import 'package:flutter/material.dart';
import 'quiz_page.dart';
import '../services/theme_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeService.themeMode,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                          ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                        ],
                        selected: {isDark ? ThemeMode.dark : ThemeMode.light},
                        onSelectionChanged: (set) {
                          if (set.contains(ThemeMode.dark)) {
                            ThemeService.setDark();
                          } else {
                            ThemeService.setLight();
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const QuizPage()),
              (route) => false,
            );
          }
        },
      ),
    );
  }
}


