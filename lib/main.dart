import 'package:flutter/material.dart';
import 'screens/quiz_page.dart';
import 'services/theme_service.dart';

void main() {
  runApp(const MyApp());
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
