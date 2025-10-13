import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Mission {
  final String id;
  final String title;
  final int rewardExp;
  final int target;
  int progress;
  bool completed;

  Mission({
    required this.id,
    required this.title,
    required this.rewardExp,
    required this.target,
    this.progress = 0,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'rewardExp': rewardExp,
        'target': target,
        'progress': progress,
        'completed': completed,
      };

  factory Mission.fromJson(Map<String, dynamic> m) => Mission(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        rewardExp: (m['rewardExp'] as num?)?.toInt() ?? 0,
        target: (m['target'] as num?)?.toInt() ?? 0,
        progress: (m['progress'] as num?)?.toInt() ?? 0,
        completed: m['completed'] as bool? ?? false,
      );
}

class Medal {
  final String id;
  final String name;
  final String description;
  bool unlocked;
  Medal({required this.id, required this.name, required this.description, this.unlocked = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'unlocked': unlocked,
      };
  factory Medal.fromJson(Map<String, dynamic> m) => Medal(
        id: (m['id'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        description: (m['description'] ?? '').toString(),
        unlocked: m['unlocked'] as bool? ?? false,
      );
}

class ProgressService {
  ProgressService._internal();
  static final ProgressService instance = ProgressService._internal();

  static const String _kExp = 'progress_exp_v1';
  static const String _kMissions = 'progress_missions_v1';
  static const String _kMedals = 'progress_medals_v1';
  static const String _kStats = 'progress_stats_v1';

  int totalExp = 0;
  List<Mission> todaysMissions = <Mission>[];
  List<Medal> medals = <Medal>[];

  // Stats
  int totalQuestions = 0;
  int correct = 0;
  int wrong = 0;
  int totalChats = 0;
  Map<String, Map<String, int>> perSubject = <String, Map<String, int>>{}; // subject => {total, correct, wrong}

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    totalExp = prefs.getInt(_kExp) ?? 0;

    // Missions
    final mRaw = prefs.getString(_kMissions);
    if (mRaw != null && mRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(mRaw) as List;
        todaysMissions = list.map((e) => Mission.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    if (todaysMissions.isEmpty) _resetDailyMissions();

    // Medals
    final mdRaw = prefs.getString(_kMedals);
    if (mdRaw != null && mdRaw.isNotEmpty) {
      try {
        final List list = jsonDecode(mdRaw) as List;
        medals = list.map((e) => Medal.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    if (medals.isEmpty) _initDefaultMedals();

    // Stats
    final stRaw = prefs.getString(_kStats);
    if (stRaw != null && stRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> m = jsonDecode(stRaw) as Map<String, dynamic>;
        totalQuestions = (m['totalQuestions'] as num?)?.toInt() ?? 0;
        correct = (m['correct'] as num?)?.toInt() ?? 0;
        wrong = (m['wrong'] as num?)?.toInt() ?? 0;
        totalChats = (m['totalChats'] as num?)?.toInt() ?? 0;
        final subj = m['perSubject'] as Map<String, dynamic>?;
        if (subj != null) {
          perSubject = subj.map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((k2, v2) => MapEntry(k2, (v2 as num).toInt()))));
        }
      } catch (_) {}
    }
  }

  void _resetDailyMissions() {
    todaysMissions = [
      Mission(id: 'm1', title: 'Answer 20 English questions', rewardExp: 200, target: 20),
      Mission(id: 'm2', title: 'Chat with AI Assistant 3 times', rewardExp: 100, target: 3),
      Mission(id: 'm3', title: 'Study for 30 minutes', rewardExp: 150, target: 30),
    ];
    _persistMissions();
  }

  void _initDefaultMedals() {
    medals = [
      Medal(id: 'medal_start', name: '🏅 Getting Started', description: 'Complete your first mission'),
      Medal(id: 'medal_combo', name: '🔥 Combo Master', description: 'Reach 10 SSS combos'),
      Medal(id: 'medal_chat', name: '💬 Chatterbox', description: 'Chat with AI Assistant 50 times'),
      Medal(id: 'medal_learner', name: '🎓 Diligent Learner', description: 'Answer 100 questions'),
      Medal(id: 'medal_perfect', name: '💎 Perfectionist', description: 'Achieve accuracy above 90%'),
    ];
    _persistMedals();
  }

  Future<void> claimAll() async {
    int gain = 0;
    for (final m in todaysMissions) {
      if (m.progress >= m.target && !m.completed) {
        gain += m.rewardExp;
        m.completed = true;
      }
    }
    if (gain > 0) {
      totalExp += gain;
      await _persistExp();
      _persistMissions();
      _checkMedalsAfterClaim();
    }
  }

  void _checkMedalsAfterClaim() {
    // Getting Started: any completed mission
    if (todaysMissions.any((m) => m.completed)) {
      _unlock('medal_start');
    }
    // Diligent Learner: Answer 100 questions
    if (totalQuestions >= 100) _unlock('medal_learner');
    // Chatterbox: 50 chats
    if (totalChats >= 50) _unlock('medal_chat');
    // Perfectionist: accuracy > 90%
    final acc = totalQuestions == 0 ? 0 : (correct * 100.0 / totalQuestions);
    if (acc >= 90) _unlock('medal_perfect');
    _persistMedals();
  }

  void _unlock(String id) {
    final i = medals.indexWhere((e) => e.id == id);
    if (i >= 0 && !medals[i].unlocked) medals[i].unlocked = true;
  }

  Future<void> _persistExp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kExp, totalExp);
  }

  Future<void> _persistMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(todaysMissions.map((e) => e.toJson()).toList());
    await prefs.setString(_kMissions, data);
  }

  Future<void> _persistMedals() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(medals.map((e) => e.toJson()).toList());
    await prefs.setString(_kMedals, data);
  }

  Future<void> persistStats() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'totalQuestions': totalQuestions,
      'correct': correct,
      'wrong': wrong,
      'totalChats': totalChats,
      'perSubject': perSubject,
    });
    await prefs.setString(_kStats, data);
  }

  // Helpers: call at appropriate places in app
  Future<void> recordAnswer({required String subject, required bool isCorrect}) async {
    totalQuestions++;
    if (isCorrect) correct++; else wrong++;
    perSubject.putIfAbsent(subject, () => {'total': 0, 'correct': 0, 'wrong': 0});
    perSubject[subject]!['total'] = (perSubject[subject]!['total'] ?? 0) + 1;
    perSubject[subject]![isCorrect ? 'correct' : 'wrong'] = (perSubject[subject]![isCorrect ? 'correct' : 'wrong'] ?? 0) + 1;
    // Mission hooks
    if (subject.contains('English')) {
      final m = todaysMissions.where((e) => e.id == 'm1').firstOrNull;
      if (m != null && !m.completed) { m.progress = (m.progress + 1).clamp(0, m.target); _persistMissions(); }
    }
    await persistStats();
  }

  Future<void> recordChat() async {
    totalChats++;
    final m = todaysMissions.where((e) => e.id == 'm2').firstOrNull;
    if (m != null && !m.completed) { m.progress = (m.progress + 1).clamp(0, m.target); _persistMissions(); }
    await persistStats();
  }
}

extension _SafeFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}


