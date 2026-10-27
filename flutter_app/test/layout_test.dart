import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parola_cemberi/game.dart';
import 'package:parola_cemberi/play_screen.dart';
import 'package:parola_cemberi/services.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(393, 852),
    const Size(430, 932),
  ]) {
    for (final keyboard in [false, true]) {
      testWidgets('Controls remain reachable at $size, keyboard $keyboard', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard ? 280 : 0);
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final profile = Profile(await SharedPreferences.getInstance())
          ..sound = false
          ..haptics = false;
        GameEngine create() => GameEngine([
          Question.fromJson({
            'id': 'museum',
            'initialLetter': 'M',
            'answer': 'MÜZE',
            'letterCount': 4,
            'clue':
                'Sanat ve bilim eserlerinin veya sanat ve bilime yarayan nesnelerin saklandığı, halka gösterilmek için sergilendiği yer veya yapı.',
          }),
        ]);
        final game = create();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: PlayScreen(
              game: game,
              profile: profile,
              audio: GameAudio(profile),
              ads: Ads(),
              replay: create,
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(const Key('pass')).hitTestable(), findsOneWidget);
        expect(find.byKey(const Key('submit')).hitTestable(), findsOneWidget);
        expect(find.byKey(const Key('hint')).hitTestable(), findsOneWidget);
        expect(find.byKey(const Key('skip')).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (!keyboard) {
          game.finish(completed: false);
          await tester.pump();
          expect(
            find.byKey(const Key('result-home')).hitTestable(),
            findsOneWidget,
          );
          expect(find.byKey(const Key('replay')).hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
