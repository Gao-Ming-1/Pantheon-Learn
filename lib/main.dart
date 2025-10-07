import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/quiz_page.dart';
import 'services/theme_service.dart';
import 'services/audio_service.dart';
import 'services/history_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    print('main start');
    await ThemeService.init();
    await AudioService.instance.init();
    await HistoryService.init();
    runApp(const MyApp());
    print('runApp done');
  }, (error, stack) {
    // ignore log
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Pantheon Learn',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: mode,
          home: const QuizPage(),
        );
      },
    );
  }
}
