import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parola_cemberi/main.dart';
import 'package:parola_cemberi/game.dart';
import 'package:parola_cemberi/services.dart';
import 'package:parola_cemberi/play_screen.dart';
import 'package:parola_cemberi/design.dart';

// Finite pumps: the live game timer intentionally keeps scheduling frames.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  debugPrint('SMOKE: entry');
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> shot(String name) async {
    // Android's Flutter image-surface conversion can stall host GPU emulators.
    // Android screenshots are captured from adb after the test instead.
    if (Platform.isIOS) await binding.takeScreenshot(name);
  }

  testWidgets(
    'Full menu, language, keyboard, jokers, review and replay smoke test',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final profile = Profile(await SharedPreferences.getInstance())
        ..onboarded = true;
      final bank = QuestionBank();
      await bank.load();
      final audio = GameAudio(profile);
      await audio.initialize();
      debugPrint('SMOKE: audio ready');
      await tester.pumpWidget(
        ParolaApp(bank: bank, profile: profile, audio: audio, ads: Ads()),
      );
      await settle(tester);
      debugPrint('SMOKE: menu ready');
      await shot('menu');
      await tester.tap(find.byKey(const Key('learn')));
      await settle(tester);
      expect(find.text('İngilizce'), findsOneWidget);
      expect(find.text('Almanca'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Azerbaycanca'), 300);
      expect(find.text('Azerbaycanca'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('İngilizce'), -300);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await settle(tester);
      await tester.tap(find.byKey(const Key('language-english')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('level-A2')));
      await settle(tester);
      expect(find.byType(PlayScreen), findsNothing);
      await tester.tap(find.byKey(const Key('level-A1')));
      await settle(tester);
      final game = tester.widget<PlayScreen>(find.byType(PlayScreen)).game;
      // This test checks UI, not countdown speed (covered by game_test.dart).
      // A slow software-rendered emulator must not expire during IME setup.
      game.seconds = 3600;
      debugPrint('SMOKE: language game ready');
      await tester.tap(find.byKey(const Key('hint')));
      await settle(tester);
      expect(game.hints, 2);
      final first = game.current.question.letter;
      await tester.tap(find.byKey(const Key('pass')));
      await settle(tester);
      expect(game.current.question.letter, isNot(first));
      await tester.tap(find.byKey(const Key('skip')));
      await settle(tester);
      expect(game.skips, 1);
      for (var i = 0; i < 3; i++) {
        await tester.enterText(
          find.byKey(const Key('answer')),
          game.current.question.answer,
        );
        await settle(tester);
        await tester.tap(find.byKey(const Key('submit')));
        await tester.pump(const Duration(milliseconds: 800));
        await settle(tester);
      }
      expect(game.streak, 3);
      debugPrint('SMOKE: jokers and answers passed');
      await tester.tap(find.byKey(const Key('answer')));
      await settle(tester);
      expect(find.byKey(const Key('pass')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('submit')).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await shot('keyboard');
      FocusManager.instance.primaryFocus?.unfocus();
      await settle(tester);
      game.setPaused(true);
      await settle(tester);
      await shot('game');
      game.setPaused(false);
      game.answer('YANLIŞ CEVAP');
      game.finish(completed: false);
      await settle(tester);
      expect(
        find.byKey(const Key('result-home')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byKey(const Key('replay')).hitTestable(), findsOneWidget);
      expect(find.textContaining('Cevabın:'), findsWidgets);
      await shot('results');
      debugPrint('SMOKE: results passed');
      await tester.tap(find.byKey(const Key('replay')));
      await settle(tester);
      expect(
        tester.widget<LetterWheel>(find.byType(LetterWheel)).game.finished,
        false,
      );
      await tester.tap(find.byKey(const Key('pause')));
      await settle(tester);
      expect(find.text('Küçük bir mola'), findsOneWidget);
      await tester.tap(find.text('Ana menü'));
      await settle(tester);
      await tester.tap(find.byKey(const Key('back')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('back')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('start')));
      await settle(tester);
      expect(
        tester.widget<PlayScreen>(find.byType(PlayScreen)).game.tiles.length,
        28,
      );
      expect(tester.takeException(), isNull);
      // Leave a live classic game on screen for the final visual comparison.
      await audio.dispose();
    },
  );
}
