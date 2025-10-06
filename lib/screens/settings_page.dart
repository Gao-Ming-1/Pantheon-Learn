import 'package:flutter/material.dart';
import 'quiz_page.dart';
import '../services/theme_service.dart';
import 'history_page.dart';
import '../data/english_dict.dart';
import 'word_list_page.dart';
import '../services/audio_service.dart';

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
            // Volume control (0-100) with snapping
            const Text(
              'Volume',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            FutureBuilder(
              future: AudioService.instance.init(),
              builder: (context, snapshot) {
                final initial =
                    AudioService.instance.getVolumePercent().toDouble();
                return StatefulBuilder(
                  builder: (context, setLocal) {
                    double value = initial;
                    return Slider(
                      value: value,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${value.round()}%',
                      onChanged: (v) {
                        // snap to nearest 10 when close
                        double snapped = v;
                        final nearest10 = (v / 10).round() * 10;
                        if ((v - nearest10).abs() <= 2)
                          snapped = nearest10.toDouble();
                        setLocal(() {});
                        AudioService.instance.setVolumePercent(snapped.round());
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Word List',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // O/PSLE Word List Buttons
            Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => WordListPage(words: englishWordDictOlevel),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.menu_book),
                    title: Text('O-Level Word List'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (englishWordDictPSLE.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PSLE Word List is empty')),
                    );
                    return;
                  }

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WordListPage(words: englishWordDictPSLE),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.menu_book),
                    title: Text('PSLE Word List'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.history),
                    title: Text('View history'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
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
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                          ),
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
            const SizedBox(height: 16),
            // How to Use (English)
            Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('How to Use (English)'),
                          content: const Text(
                            'Welcome to the English Practice App!\n\n'
                            '1. Select a subject and start answering questions.\n'
                            '2. If you keep answering correctly, your combo level increases and cool effects appear!\n'
                            '3. If you stop or answer wrong, the combo slowly drops.\n'
                            '4. You can also explore other subjects with AI-generated questions.\n\n'
                            'Have fun improving your English!',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('How to Use (English)'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
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
