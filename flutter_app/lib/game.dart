import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum TileState { waiting, active, correct, wrong, passed, skipped }

class Language {
  final String id, title, nativeName, flag, alphabet;
  const Language(
    this.id,
    this.title,
    this.nativeName,
    this.flag,
    this.alphabet,
  );
  static const all = [
    Language(
      'english',
      'İngilizce',
      'English',
      'GB',
      'ABCDEFGHIJKLMNOPQRSTUVWYZ',
    ),
    Language('italian', 'İtalyanca', 'Italiano', 'IT', 'ABCDEFGHILMNOPQRSTUVZ'),
    Language(
      'german',
      'Almanca',
      'Deutsch',
      'DE',
      'ABCDEFGHIJKLMNOPQRSTUVWYZÄÖÜ',
    ),
    Language(
      'dutch',
      'Felemenkçe',
      'Nederlands',
      'NL',
      'ABCDEFGHIJKLMNOPRSTUVWZ',
    ),
    Language(
      'spanish',
      'İspanyolca',
      'Español',
      'ES',
      'ABCDEFGHIJKLMNÑOPQRSTUVWYZ',
    ),
    Language(
      'azerbaijani',
      'Azerbaycanca',
      'Azərbaycanca',
      'AZ',
      'ABCÇDEƏFGHIİJKQLMNOÖPRSŞTUÜVYZ',
    ),
  ];
  static const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static bool unlocked(String level) =>
      const ['A1', 'B1', 'C1'].contains(level);
}

class Question {
  final String id, clue, answer, letter, category, hint, rule;
  final String? level;
  final List<String> alternatives;
  final int length;
  Question.fromJson(Map<String, dynamic> j)
    : id = j['id'],
      clue = j['clue'],
      answer = j['answer'],
      letter = j['initialLetter'],
      category = j['category'] ?? 'Genel Kültür',
      hint = j['extendedClue'] ?? '',
      rule = j['letterRule'] ?? 'startsWith',
      level = j['cefrLevel'],
      length = j['letterCount'] ?? (j['answer'] as String).length,
      alternatives = List<String>.from(j['acceptedAnswers'] ?? []);
}

String normalizeAnswer(String value, String language) {
  var s = value.trim();
  if (language == 'turkish' || language == 'azerbaijani') {
    s = s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  } else {
    s = s.toLowerCase().replaceAll('ß', 'ss');
    const from = 'àáâãäåèéêëìíîïòóôõöùúûüç';
    const to = 'aaaaaaeeeeiiiiooooouuuuc';
    for (var i = 0; i < from.length; i++) {
      s = s.replaceAll(from[i], to[i]);
    }
  }
  return s
      .replaceAll(RegExp(r'[^a-z0-9ıiğşçöüəñ\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class QuestionBank {
  final Map<String, List<Question>> data = {};
  Future<void> load() async {
    for (final id in ['turkish', ...Language.all.map((l) => l.id)]) {
      final file = id == 'turkish'
          ? 'parola_cemberi_5000_soru.json'
          : 'parola_cemberi_${id}_cefr.json';
      final raw =
          jsonDecode(await rootBundle.loadString('assets/questions/$file'))
              as List;
      data[id] = raw.map((j) => Question.fromJson(j)).toList();
    }
  }

  int count(String id, [String? level]) =>
      (data[id] ?? []).where((q) => level == null || q.level == level).length;
  List<Question> round({
    Language? language,
    String? level,
    bool quick = false,
    int? seed,
    String? category,
  }) {
    final random = Random(seed);
    final source = (data[language?.id ?? 'turkish'] ?? [])
        .where((q) => level == null || q.level == level)
        .toList();
    final alphabet = language?.alphabet ?? 'ABCÇDEFGHIİJKLMNOÖPRSŞTUÜVYZ';
    final questions = <Question>[];
    for (final letter in alphabet.split('')) {
      var choices = source.where((q) => q.letter == letter).toList();
      if (category != null) {
        final filtered = choices.where((q) => q.category == category).toList();
        if (filtered.isNotEmpty) choices = filtered;
      }
      if (choices.isNotEmpty) {
        questions.add(choices[random.nextInt(choices.length)]);
      }
    }
    if (quick) {
      questions.shuffle(random);
      return questions.take(10).toList();
    }
    return questions;
  }
}

class RoundTile {
  final Question question;
  TileState state = TileState.waiting;
  int passes = 0;
  bool hinted = false;
  String submitted = '';
  RoundTile(this.question);
}

class GameEngine extends ChangeNotifier {
  final List<RoundTile> tiles;
  final Language? language;
  final String? level;
  final bool quick, daily;
  final String sessionId = '${DateTime.now().microsecondsSinceEpoch}';
  final List<int> _queue = [];
  int index = 0,
      seconds,
      score = 0,
      streak = 0,
      bestStreak = 0,
      hints = 3,
      skips = 2;
  bool paused = false, finished = false;
  int get correct => tiles.where((t) => t.state == TileState.correct).length;
  int get wrong => tiles.where((t) => t.state == TileState.wrong).length;
  int get reward => max(20, correct * 8);
  RoundTile get current => tiles[index];
  GameEngine(
    List<Question> questions, {
    this.language,
    this.level,
    this.quick = false,
    this.daily = false,
    int? duration,
  }) : tiles = questions.map(RoundTile.new).toList(),
       seconds = duration ?? (quick ? 60 : 120) {
    if (tiles.isEmpty) {
      finished = true;
      return;
    }
    tiles.first.state = TileState.active;
  }
  void tick() {
    if (paused || finished) return;
    seconds = max(0, seconds - 1);
    if (seconds == 0) finish(completed: false);
    notifyListeners();
  }

  void setPaused(bool value) {
    paused = value;
    notifyListeners();
  }

  bool? answer(String value) {
    if (finished || paused || value.trim().isEmpty) return null;
    final tile = current;
    tile.submitted = value.trim();
    final id = language?.id ?? 'turkish';
    final normalized = normalizeAnswer(value, id);
    final success = [
      tile.question.answer,
      ...tile.question.alternatives,
    ].any((a) => normalizeAnswer(a, id) == normalized);
    tile.state = success ? TileState.correct : TileState.wrong;
    if (success) {
      streak++;
      bestStreak = max(bestStreak, streak);
      if (language != null) {
        score += (tile.hinted ? 60 : 100) + 15 * (streak - 1);
      } else {
        var points = tile.hinted
            ? (quick
                  ? 70
                  : daily
                  ? 55
                  : 60)
            : (quick ? 120 : 100);
        if (tile.passes > 0) points = (points * (quick ? .75 : .8)).round();
        score +=
            points +
            ({
                  3: quick ? 30 : 25,
                  5: quick ? 70 : 50,
                  10: quick ? 150 : 100,
                }[streak] ??
                0);
      }
    } else {
      streak = 0;
    }
    _advance();
    return success;
  }

  void pass() {
    if (finished || paused) return;
    final tile = current;
    tile.passes++;
    tile.state = TileState.passed;
    if (tile.passes < 2) _queue.add(index);
    _advance();
  }

  bool skip() {
    if (finished || paused || skips == 0) return false;
    skips--;
    current.state = TileState.skipped;
    _advance();
    return true;
  }

  bool hint() {
    if (finished || paused || hints == 0 || current.hinted) return false;
    hints--;
    current.hinted = true;
    notifyListeners();
    return true;
  }

  void _advance() {
    final waiting = tiles.indexWhere((t) => t.state == TileState.waiting);
    if (waiting >= 0) {
      index = waiting;
    } else if (_queue.isNotEmpty) {
      index = _queue.removeAt(0);
    } else {
      finish();
      return;
    }
    current.state = TileState.active;
    notifyListeners();
  }

  void finish({bool completed = true}) {
    if (finished) return;
    finished = true;
    if (completed) score += seconds * (quick ? 3 : 2);
    notifyListeners();
  }
}
