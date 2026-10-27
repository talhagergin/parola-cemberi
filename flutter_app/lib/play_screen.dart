import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design.dart';
import 'game.dart';
import 'services.dart';

class PlayScreen extends StatefulWidget {
  final GameEngine game;
  final Profile profile;
  final GameAudio audio;
  final Ads ads;
  final GameEngine Function() replay;
  const PlayScreen({
    super.key,
    required this.game,
    required this.profile,
    required this.audio,
    required this.ads,
    required this.replay,
  });
  @override
  State<PlayScreen> createState() => _PlayState();
}

class _PlayState extends State<PlayScreen> with WidgetsBindingObserver {
  final answer = TextEditingController();
  final focus = FocusNode();
  late GameEngine game;
  Timer? timer, feedbackTimer;
  String? feedback;
  bool busy = false, handled = false, pauseDialog = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    game = widget.game;
    game.addListener(changed);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final before = game.seconds;
      game.tick();
      if (before == 16 && game.seconds == 15) {
        unawaited(widget.audio.play('warning'));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    feedbackTimer?.cancel();
    game.removeListener(changed);
    game.dispose();
    answer.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !game.finished && !pauseDialog) {
      unawaited(pause());
    }
  }

  void changed() {
    if (!mounted) return;
    if (game.finished && !handled) {
      handled = true;
      focus.unfocus();
      unawaited(widget.audio.play('complete'));
      final due = widget.profile.record(game);
      if (due) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(widget.ads.show());
        });
      }
    }
    setState(() {});
  }

  void vibrate() {
    if (widget.profile.haptics) unawaited(HapticFeedback.lightImpact());
  }

  void submit() {
    if (busy || game.finished || game.paused || answer.text.trim().isEmpty) {
      return;
    }
    final value = answer.text;
    answer.clear();
    busy = true;
    final success = game.answer(value);
    vibrate();
    if (success == null) {
      busy = false;
      return;
    }
    if (!game.finished) {
      unawaited(
        widget.audio.play(
          success ? (game.streak >= 3 ? 'streak' : 'correct') : 'wrong',
        ),
      );
    }
    setState(
      () => feedback = success
          ? (game.streak >= 3 ? '${game.streak} DOĞRU • ALEV ALDIN!' : 'DOĞRU!')
          : 'BİR SONRAKİNE!',
    );
    feedbackTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          feedback = null;
          busy = false;
        });
      }
    });
  }

  void pass() {
    if (busy || game.paused) return;
    answer.clear();
    game.pass();
    vibrate();
    if (!game.finished) unawaited(widget.audio.play('pass'));
  }

  void skip() {
    if (busy) return;
    if (game.skip()) {
      answer.clear();
      vibrate();
      if (!game.finished) unawaited(widget.audio.play('pass'));
    }
  }

  void hint() {
    if (busy) return;
    if (game.hint()) {
      vibrate();
      unawaited(widget.audio.play('hint'));
    }
  }

  Future<void> pause() async {
    if (game.finished || pauseDialog) return;
    pauseDialog = true;
    game.setPaused(true);
    focus.unfocus();
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: panel,
        title: const Text('Küçük bir mola'),
        content: const Text(
          'Süre durduruldu. Hazır olduğunda devam edebilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ana menü'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Devam et'),
          ),
        ],
      ),
    );
    pauseDialog = false;
    if (!mounted) return;
    if (leave == true) {
      Navigator.pop(context);
    } else {
      game.setPaused(false);
    }
  }

  void replay() {
    if (game.daily) {
      Navigator.pop(context);
      return;
    }
    game.removeListener(changed);
    game.dispose();
    game = widget.replay();
    game.addListener(changed);
    handled = false;
    busy = false;
    feedback = null;
    answer.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: game.finished,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(pause());
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Space(
          child: SafeArea(
            child: game.finished
                ? results()
                : LayoutBuilder(
                    builder: (c, box) {
                      final wheelHeight = keyboard && box.maxHeight < 430
                          ? 0.0
                          : min(
                              box.maxWidth - 30,
                              keyboard
                                  ? min(150.0, max(100.0, box.maxHeight * .24))
                                  : max(130.0, box.maxHeight * .48),
                            );
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  key: const Key('pause'),
                                  onPressed: () => pause(),
                                  icon: const Icon(
                                    Icons.pause_rounded,
                                    color: cyan,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    keyboard
                                        ? '${game.current.question.letter} • ${(game.seconds ~/ 60).toString().padLeft(2, '0')}:${(game.seconds % 60).toString().padLeft(2, '0')} • ${game.score} P'
                                        : game.language == null
                                        ? (game.quick
                                              ? 'HIZLI TUR'
                                              : game.daily
                                              ? 'GÜNLÜK ÇEMBER'
                                              : 'PAROLA ÇEMBERİ')
                                        : '${game.language!.title} • ${game.level}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .06),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${game.correct}/${game.tiles.length}',
                                    style: const TextStyle(
                                      color: cyan,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: wheelHeight,
                            child: LetterWheel(
                              game,
                              theme: widget.profile.theme,
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              child: questionCard(keyboard),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    joker(
                                      'İPUCU',
                                      Icons.lightbulb_rounded,
                                      game.hints,
                                      hint,
                                      key: const Key('hint'),
                                      enabled:
                                          game.hints > 0 &&
                                          !game.current.hinted,
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: navy.withValues(alpha: .65),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: focus.hasFocus
                                                ? cyan
                                                : purple,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: TextField(
                                          key: const Key('answer'),
                                          controller: answer,
                                          focusNode: focus,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          textCapitalization:
                                              TextCapitalization.none,
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (_) => submit(),
                                          onChanged: (_) => setState(() {}),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Cevabını yaz…',
                                            hintStyle: TextStyle(
                                              color: muted.withValues(
                                                alpha: .5,
                                              ),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                  vertical: 15,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    joker(
                                      'ATLA',
                                      Icons.fast_forward_rounded,
                                      game.skips,
                                      skip,
                                      key: const Key('skip'),
                                      enabled: game.skips > 0,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GlowButton(
                                        'PAS',
                                        key: const Key('pass'),
                                        onTap: busy ? null : pass,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GlowButton(
                                        'CEVAPLA',
                                        key: const Key('submit'),
                                        warm: true,
                                        onTap:
                                            busy || answer.text.trim().isEmpty
                                            ? null
                                            : submit,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget joker(
    String text,
    IconData icon,
    int count,
    VoidCallback tap, {
    Key? key,
    bool enabled = true,
  }) => SizedBox(
    width: 57,
    child: Semantics(
      label: '$text, $count hak',
      button: true,
      child: InkWell(
        key: key,
        onTap: enabled && !busy ? tap : null,
        borderRadius: BorderRadius.circular(17),
        child: Opacity(
          opacity: enabled ? .99 : .35,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [purple.withValues(alpha: .6), const Color(0xFF1E2754)],
              ),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Badge(
                  label: Text('$count'),
                  child: Icon(
                    icon,
                    color: text == 'İPUCU' ? Colors.amber : cyan,
                    size: 25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget questionCard(bool compact) {
    final t = game.current;
    final q = t.question;
    return Glass(
      padding: EdgeInsets.all(compact ? 15 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${q.letter} HARFİ',
                style: const TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  game.language != null
                      ? 'Türkçe → ${game.language!.nativeName}'
                      : q.category,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            q.clue,
            style: TextStyle(
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${q.length} harf${q.rule == 'contains' ? ' • ${q.letter} içerir' : ''}',
                style: const TextStyle(color: muted, fontSize: 13),
              ),
              const Spacer(),
              if (feedback != null)
                Flexible(
                  child: Text(
                    feedback!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: orange,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          if (t.hinted) ...[
            const SizedBox(height: 12),
            Text(
              game.language != null || q.hint.isEmpty
                  ? 'İpucu: ${q.answer.substring(0, min(2, q.answer.length))}${' •' * (max(0, q.length - 2))}'
                  : q.hint,
              style: const TextStyle(color: Colors.amber, fontSize: 15),
            ),
          ],
        ],
      ),
    );
  }

  Widget results() {
    final missed = game.tiles
        .where((t) => t.state != TileState.correct)
        .toList();
    return Column(
      children: [
        const SizedBox(height: 14),
        const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 50),
        const Text(
          'ÇEMBER TAMAMLANDI',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          game.language == null
              ? 'Her tur yeni bir keşif!'
              : '${game.language!.title} • ${game.level}',
          style: const TextStyle(color: muted),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Glass(
            child: Column(
              children: [
                Text(
                  '${game.score}',
                  key: const Key('result-score'),
                  style: const TextStyle(
                    fontSize: 53,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const Text(
                  'TOPLAM PUAN',
                  style: TextStyle(
                    color: cyan,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    stat('${game.correct}', 'DOĞRU', Colors.greenAccent),
                    stat('${game.wrong}', 'YANLIŞ', Colors.redAccent),
                    stat(
                      '${game.tiles.where((t) => t.state == TileState.passed || t.state == TileState.active || t.state == TileState.waiting).length}',
                      'PAS / BOŞ',
                      cyan,
                    ),
                    stat(
                      '${game.tiles.where((t) => t.state == TileState.skipped).length}',
                      'ATLA',
                      muted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '+${game.reward} ALTIN',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              Text(
                missed.isEmpty
                    ? 'Mükemmel! Bütün kelimeleri bildin.'
                    : 'TEKRAR KEŞFET • ${missed.length} KELİME',
                style: const TextStyle(
                  color: cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              for (final t in missed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Glass(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.question.letter,
                              style: const TextStyle(
                                color: cyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.question.clue,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              t.state == TileState.wrong
                                  ? 'Yanlış'
                                  : t.state == TileState.skipped
                                  ? 'Atlandı'
                                  : 'Pas / Boş',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.question.answer,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        if (t.submitted.isNotEmpty)
                          Text(
                            'Cevabın: ${t.submitted}',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: GlowButton(
                  'ANA MENÜ',
                  key: const Key('result-home'),
                  onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                ),
              ),
              if (!game.daily) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: GlowButton(
                    'TEKRAR OYNA',
                    key: const Key('replay'),
                    warm: true,
                    onTap: replay,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget stat(String value, String label, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: muted,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
