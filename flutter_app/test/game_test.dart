import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parola_cemberi/game.dart';
import 'package:parola_cemberi/services.dart';

Question q(String letter, String answer) => Question.fromJson({
  'id': answer,
  'clue': 'Test',
  'answer': answer,
  'initialLetter': letter,
  'letterCount': answer.length,
});
GameEngine round({bool quick = false, Language? language, String? level}) =>
    GameEngine(
      [q('A', 'ARABA'), q('B', 'BALIK'), q('C', 'CAM')],
      quick: quick,
      language: language,
      level: level,
    );
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Pas waits until untouched letters end, then returns', () {
    final g = round();
    g.pass();
    expect(g.index, 1);
    g.answer('BALIK');
    g.answer('CAM');
    expect(g.index, 0);
    expect(g.finished, false);
    g.answer('ARABA');
    expect(g.correct, 3);
    expect(g.finished, true);
  });
  test('Quick mode also revisits a passed letter', () {
    final g = round(quick: true);
    g.pass();
    g.answer('BALIK');
    g.answer('CAM');
    expect(g.index, 0);
    expect(g.finished, false);
  });
  test('Skip permanently removes letter and consumes one joker', () {
    final g = round();
    g.skip();
    g.answer('BALIK');
    g.answer('CAM');
    expect(g.finished, true);
    expect(g.tiles.first.state, TileState.skipped);
    expect(g.skips, 1);
  });
  test('Hint can only be charged once per question', () {
    final g = round();
    expect(g.hint(), true);
    expect(g.hint(), false);
    expect(g.hints, 2);
    g.answer('ARABA');
    expect(g.score, 60);
  });
  test('Paused timer and actions do not mutate the round', () {
    final g = round();
    g.setPaused(true);
    g.tick();
    g.pass();
    g.skip();
    expect(g.answer('ARABA'), null);
    expect(g.seconds, 120);
    expect(g.index, 0);
  });
  test('Timeout does not grant completion time bonus', () {
    final g = GameEngine([q('A', 'ARABA')], duration: 1);
    g.tick();
    expect(g.finished, true);
    expect(g.score, 0);
  });
  test('Streak bonus and wrong reset', () {
    final g = round();
    g.answer('ARABA');
    g.answer('BALIK');
    g.answer('CAM');
    expect(g.score, 565);
    expect(g.bestStreak, 3);
    final wrong = round();
    wrong.answer('ARABA');
    wrong.answer('no');
    expect(wrong.streak, 0);
  });
  test('Unicode case rules and accents', () {
    expect(normalizeAnswer(' IŞIK! ', 'turkish'), 'ışık');
    expect(normalizeAnswer('İNEK', 'turkish'), 'inek');
    expect(normalizeAnswer('Straße', 'german'), 'strasse');
    expect(normalizeAnswer('CITTÀ', 'italian'), 'citta');
    expect(normalizeAnswer('NIÑO', 'spanish'), 'niño');
    expect(normalizeAnswer('ƏLİ', 'azerbaijani'), 'əli');
  });
  test('Only A1 B1 C1 are unlocked', () {
    for (final l in Language.levels) {
      expect(Language.unlocked(l), ['A1', 'B1', 'C1'].contains(l));
    }
  });
  test('All bundled language rounds have questions and no X or Ğ', () async {
    final bank = QuestionBank();
    await bank.load();
    expect(bank.count('turkish'), 5000);
    for (final l in Language.all) {
      for (final level in Language.levels) {
        final qs = bank.round(language: l, level: level);
        expect(qs, isNotEmpty);
        expect(
          qs.every(
            (q) => q.level == level && q.clue.isNotEmpty && q.answer.isNotEmpty,
          ),
          true,
        );
        expect(qs.any((q) => ['X', 'Ğ'].contains(q.letter)), false);
        expect(qs.map((q) => q.letter).toSet().length, qs.length);
      }
    }
  });
  test('Daily seed is stable and quick has ten letters', () async {
    final bank = QuestionBank();
    await bank.load();
    expect(
      bank.round(seed: 20261027).map((q) => q.id),
      bank.round(seed: 20261027).map((q) => q.id),
    );
    expect(bank.round(quick: true).length, 10);
  });
  test('Purchase charges only once, rejects insufficient balance', () async {
    SharedPreferences.setMockInitialValues({});
    final p = Profile(await SharedPreferences.getInstance());
    expect(p.purchase('fox', 600), false);
    p.coins = 1000;
    expect(p.purchase('fox', 600), true);
    expect(p.coins, 400);
    expect(p.purchase('fox', 600), true);
    expect(p.coins, 400);
  });
  test('Reward is idempotent; normal ads every two, A1 every three', () async {
    SharedPreferences.setMockInitialValues({});
    final p = Profile(await SharedPreferences.getInstance());
    final g = round()..finish();
    expect(p.record(g), false);
    expect(p.record(g), false);
    expect(p.games, 1);
    expect(p.record(round()..finish()), true);
    final l = Language.all.first;
    expect(p.record(round(language: l, level: 'A1')..finish()), false);
    expect(p.record(round(language: l, level: 'A1')..finish()), false);
    expect(p.record(round(language: l, level: 'A1')..finish()), true);
    expect(p.record(round(language: l, level: 'B1')..finish()), false);
    expect(p.record(round(language: l, level: 'C1')..finish()), true);
  });
}
