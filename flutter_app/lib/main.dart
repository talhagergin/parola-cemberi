import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game.dart';
import 'services.dart';
import 'design.dart';
import 'screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: navy,
    ),
  );
  try {
    final bank = QuestionBank();
    final profile = Profile(await SharedPreferences.getInstance());
    await bank.load();
    final audio = GameAudio(profile);
    try {
      await audio.initialize();
    } catch (e) {
      debugPrint('Audio: $e');
    }
    final ads = Ads();
    runApp(ParolaApp(bank: bank, profile: profile, audio: audio, ads: ads));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(ads.initialize()),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Oyun yüklenemedi. Yeniden açmayı dene.\n$e'),
          ),
        ),
      ),
    );
  }
}

class ParolaApp extends StatelessWidget {
  final QuestionBank bank;
  final Profile profile;
  final GameAudio audio;
  final Ads ads;
  const ParolaApp({
    super.key,
    required this.bank,
    required this.profile,
    required this.audio,
    required this.ads,
  });
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Parola Çemberi',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cyan,
        brightness: Brightness.dark,
        primary: cyan,
        surface: panel,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
        fontFamily: 'Nunito',
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(backgroundColor: const Color(0xFF161742)),
      ),
    ),
    home: HomeScreen(bank: bank, profile: profile, audio: audio, ads: ads),
  );
}
