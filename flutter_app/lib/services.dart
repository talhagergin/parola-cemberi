import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';

class Profile extends ChangeNotifier {
  final SharedPreferences prefs;
  int coins = 250,
      highScore = 0,
      games = 0,
      correct = 0,
      total = 0,
      bestStreak = 0;
  bool sound = true, haptics = true, onboarded = false;
  String avatar = 'robot', theme = 'classic', dailyDate = '';
  Set<String> owned = {'robot', 'classic'}, rewarded = {};
  Map<String, int> adCounters = {};
  Profile(this.prefs) {
    final raw = prefs.getString('flutter_profile_v1');
    if (raw == null) return;
    try {
      final j = jsonDecode(raw);
      coins = j['coins'];
      highScore = j['highScore'];
      games = j['games'];
      correct = j['correct'];
      total = j['total'];
      bestStreak = j['bestStreak'] ?? 0;
      sound = j['sound'];
      haptics = j['haptics'] ?? true;
      onboarded = j['onboarded'];
      avatar = j['avatar'];
      theme = j['theme'];
      dailyDate = j['dailyDate'] ?? '';
      owned = Set<String>.from(j['owned']);
      rewarded = Set<String>.from(j['rewarded'] ?? []);
      adCounters = Map<String, int>.from(j['adCounters'] ?? {});
    } catch (_) {
      /* A damaged save should not prevent launch. */
    }
  }
  static String get today => DateTime.now()
      .toUtc()
      .add(const Duration(hours: 3))
      .toIso8601String()
      .substring(0, 10);
  void save() {
    unawaited(
      prefs.setString(
        'flutter_profile_v1',
        jsonEncode({
          'coins': coins,
          'highScore': highScore,
          'games': games,
          'correct': correct,
          'total': total,
          'bestStreak': bestStreak,
          'sound': sound,
          'haptics': haptics,
          'onboarded': onboarded,
          'avatar': avatar,
          'theme': theme,
          'dailyDate': dailyDate,
          'owned': owned.toList(),
          'rewarded': rewarded.toList(),
          'adCounters': adCounters,
        }),
      ),
    );
    notifyListeners();
  }

  bool purchase(String id, int cost, {bool isAvatar = true}) {
    if (!owned.contains(id)) {
      if (coins < cost) return false;
      coins -= cost;
      owned.add(id);
    }
    if (isAvatar) {
      avatar = id;
    } else {
      theme = id;
    }
    save();
    return true;
  }

  bool record(GameEngine game) {
    if (!game.finished || rewarded.contains(game.sessionId)) return false;
    rewarded.add(game.sessionId);
    // Bounded history, while retaining all sessions from this running process.
    coins += game.reward;
    games++;
    correct += game.correct;
    total += game.tiles.length;
    highScore = game.score > highScore ? game.score : highScore;
    bestStreak = game.bestStreak > bestStreak ? game.bestStreak : bestStreak;
    if (game.daily) dailyDate = today;
    final bucket = game.language == null
        ? 'normal'
        : game.level == 'A1'
        ? 'A1'
        : 'other';
    final threshold = bucket == 'A1' ? 3 : 2;
    adCounters[bucket] = (adCounters[bucket] ?? 0) + 1;
    final due = adCounters[bucket]! >= threshold;
    if (due) adCounters[bucket] = 0;
    save();
    return due;
  }
}

class GameAudio {
  static const _native = MethodChannel('parola/audio');
  final Profile profile;
  final Map<String, AudioPlayer> _players = {};
  AudioPlayer? _current;
  int _generation = 0;
  GameAudio(this.profile);
  Future<void> initialize() async {
    if (Platform.isIOS) {
      await _native.invokeMethod<void>('prepare');
      return;
    }
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ),
    );
    for (final event in [
      'correct',
      'wrong',
      'pass',
      'hint',
      'streak',
      'warning',
      'complete',
    ]) {
      final player = AudioPlayer();
      // Short SoundPool effects have no playback-position UI or completion
      // callbacks. Frame polling would otherwise keep scheduling UI frames.
      player.positionUpdater = null;
      if (Platform.isAndroid) await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(.75);
      await player.setSource(AssetSource('audio/$event.wav'));
      _players[event] = player;
    }
  }

  Future<void> play(String event) async {
    if (!profile.sound) return;
    if (Platform.isIOS) {
      try {
        await _native.invokeMethod<void>('play', event);
      } catch (e) {
        debugPrint('Audio: $e');
      }
      return;
    }
    final request = ++_generation;
    try {
      final player = _players[event];
      if (player == null) return;
      await _current?.pause();
      if (request != _generation) return;
      _current = player;
      await player.stop();
      if (request == _generation && profile.sound) await player.resume();
    } catch (e) {
      debugPrint('Audio: $e');
    }
  }

  Future<void> dispose() async {
    _generation++;
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}

// Demo IDs intentionally remain until the owner supplies real AdMob IDs.
// Never ship a store build with the demo configuration.
class Ads extends ChangeNotifier {
  static const disabled = bool.fromEnvironment('DISABLE_ADS');
  bool ready = false;
  InterstitialAd? _interstitial;
  bool _loading = false;
  String get interstitialId => Platform.isIOS
      ? const String.fromEnvironment(
          'ADMOB_INTERSTITIAL_IOS',
          defaultValue: 'ca-app-pub-3940256099942544/4411468910',
        )
      : const String.fromEnvironment(
          'ADMOB_INTERSTITIAL_ANDROID',
          defaultValue: 'ca-app-pub-3940256099942544/1033173712',
        );
  String get bannerId => Platform.isIOS
      ? const String.fromEnvironment(
          'ADMOB_BANNER_IOS',
          defaultValue: 'ca-app-pub-3940256099942544/2435281174',
        )
      : const String.fromEnvironment(
          'ADMOB_BANNER_ANDROID',
          defaultValue: 'ca-app-pub-3940256099942544/6300978111',
        );
  Future<void> initialize() async {
    if (disabled) return;
    // Google's public demo account has no publisher consent form. Only demo
    // units use this path; a real publisher configuration always requires UMP.
    if (interstitialId.startsWith('ca-app-pub-3940256099942544/') &&
        bannerId.startsWith('ca-app-pub-3940256099942544/')) {
      await _enable();
      return;
    }
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) async {
          await _start();
        });
      },
      (error) async {
        await _start();
      },
    );
  }

  Future<void> _start() async {
    if (ready || !await ConsentInformation.instance.canRequestAds()) return;
    await _enable();
  }

  Future<void> _enable() async {
    if (ready) return;
    await MobileAds.instance.initialize();
    ready = true;
    notifyListeners();
    preload();
  }

  void preload() {
    if (!ready || _loading || _interstitial != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          debugPrint('Ad unavailable: $error');
        },
      ),
    );
  }

  Future<void> show() async {
    final ad = _interstitial;
    if (ad == null) {
      preload();
      return;
    }
    _interstitial = null;
    final done = Completer<void>();
    void finish() {
      ad.dispose();
      if (!done.isCompleted) done.complete();
      preload();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, error) => finish(),
    );
    await ad.show();
    await done.future;
  }

  Future<void> privacy() async {
    await ConsentForm.showPrivacyOptionsForm((error) {});
  }
}
