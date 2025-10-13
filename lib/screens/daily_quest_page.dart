import 'package:flutter/material.dart';
import 'package:mcq_creator/screens/quiz_page.dart';
import 'package:mcq_creator/screens/settings_page.dart';
import '../services/progress_service.dart';

class DailyQuestPage extends StatefulWidget {
  const DailyQuestPage({super.key});

  @override
  State<DailyQuestPage> createState() => _DailyQuestPageState();
}

class _DailyQuestPageState extends State<DailyQuestPage> with SingleTickerProviderStateMixin {
  final ProgressService svc = ProgressService.instance;
  late final AnimationController _expAnim;
  double _expAnimValue = 0;

  @override
  void initState() {
    super.initState();
    _expAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _init();
    // listen changes
    ProgressService.instance.changeTick.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _init() async {
    await ProgressService.instance.init();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _expAnim.dispose();
    super.dispose();
  }

  int _rankThreshold(int exp) {
    if (exp >= 11000) return 11000;
    if (exp >= 8000) return 8000;
    if (exp >= 5500) return 5500;
    if (exp >= 3500) return 3500;
    if (exp >= 2000) return 2000;
    if (exp >= 1000) return 1000;
    if (exp >= 500) return 500;
    return 0;
  }

  String _rankLabel(int exp) {
    if (exp >= 11000) return 'MASTER 👑';
    if (exp >= 8000) return 'DIAMOND 💎';
    if (exp >= 5500) return 'PLATINUM 🥇';
    if (exp >= 3500) return 'GOLD 🥇';
    if (exp >= 2000) return 'SILVER 🥈';
    if (exp >= 1000) return 'BRONZE 🥉';
    if (exp >= 500) return 'IRON';
    return 'ROOKIE';
  }

  @override
  Widget build(BuildContext context) {
    final exp = svc.totalExp;
    final base = _rankThreshold(exp);
    final next = _rankThreshold(base + 1 == 11000 ? base : base + 1 << 31 == 0 ? base : base); // guard
    final nextThreshold = () {
      if (exp >= 11000) return 13000; // arbitrary cap
      if (exp >= 8000) return 11000;
      if (exp >= 5500) return 8000;
      if (exp >= 3500) return 5500;
      if (exp >= 2000) return 3500;
      if (exp >= 1000) return 2000;
      if (exp >= 500) return 1000;
      return 500;
    }();
    final progress = ((exp - base) / (nextThreshold - base)).clamp(0.0, 1.0);

    return Scaffold(
      // remove top app bar to appear as standalone page
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Daily Quest', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            // Rank + EXP Progress
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rank: ${_rankLabel(exp)}'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text('EXP: $exp / $nextThreshold')
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Missions
            Text('Today\'s Missions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...svc.todaysMissions.map((m) {
              final pct = (m.progress / m.target).clamp(0.0, 1.0);
              return Card(
                elevation: 1,
                child: ListTile(
                  title: Text(m.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: pct),
                      const SizedBox(height: 4),
                      Text('${m.progress}/${m.target}  •  +${m.rewardExp} EXP'),
                    ],
                  ),
                  trailing: Icon(m.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: m.completed ? Colors.green : null),
                ),
              );
            }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final before = svc.totalExp;
                  await svc.claimAll();
                  setState(() {});
                  // Animate exp gain
                  _expAnimValue = 0;
                  _expAnim.forward(from: 0);
                },
                child: const Text('Claim All Rewards'),
              ),
            ),
            const SizedBox(height: 16),
            // Medals
            Text('Achievements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: svc.medals.map((md) {
                return Container(
                  width: 180,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        md.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: md.unlocked ? Colors.orange : Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        md.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: md.unlocked ? null : Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Icon(md.unlocked ? Icons.emoji_events : Icons.lock_outline, color: md.unlocked ? Colors.orange : Colors.grey),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Stats
            Text('Statistics', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _StatsPanel(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            label: 'Quest',
          ),
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
          } else if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
          } else if (index == 1) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DailyQuestPage()));
          }
        },
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final ProgressService svc = ProgressService.instance;
  _StatsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final acc = svc.totalQuestions == 0 ? 0 : (svc.correct * 100.0 / svc.totalQuestions);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statTile(context, 'Total Questions', svc.totalQuestions.toString()),
                _statTile(context, 'Correct', svc.correct.toString()),
                _statTile(context, 'Wrong', svc.wrong.toString()),
                _statTile(context, 'Accuracy', '${acc.toStringAsFixed(1)}%'),
                _statTile(context, 'AI Chats', svc.totalChats.toString()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Per Subject'),
                const SizedBox(height: 8),
                Column(
                  children: svc.perSubject.entries.map((e) {
                    final total = e.value['total'] ?? 0;
                    final correct = e.value['correct'] ?? 0;
                    final wrong = e.value['wrong'] ?? 0;
                    final a = total == 0 ? 0 : (correct * 100.0 / total);
                    return ListTile(
                      dense: true,
                      title: Text(e.key),
                      subtitle: LinearProgressIndicator(value: total == 0 ? 0 : correct / total),
                      trailing: Text('${a.toStringAsFixed(1)}%'),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _statTile(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}


