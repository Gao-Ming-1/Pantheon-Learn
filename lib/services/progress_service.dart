import 'dart:convert';
import 'package:flutter/material.dart';
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
  static const String _kDailyDate = 'progress_daily_date_v1';

  int totalExp = 0;
  List<Mission> todaysMissions = <Mission>[];
  List<Medal> medals = <Medal>[];

  // Stats
  int totalQuestions = 0;
  int correct = 0;
  int wrong = 0;
  int totalChats = 0;
  Map<String, Map<String, int>> perSubject = <String, Map<String, int>>{}; // subject => {total, correct, wrong}
  int currentStreak = 0;
  // UI update hook
  final ValueNotifier<int> changeTick = ValueNotifier<int>(0);

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
    // Daily reset by date
    final last = prefs.getString(_kDailyDate);
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    if (todaysMissions.isEmpty || last != todayKey) {
      _resetDailyMissions();
      await prefs.setString(_kDailyDate, todayKey);
    }
    _notify();

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
      Mission(id: 'm1', title: 'Answer 20 questions today', rewardExp: 200, target: 20),
      Mission(id: 'm2', title: 'Chat with AI Assistant 3 times', rewardExp: 100, target: 3),
      Mission(id: 'm3', title: 'Achieve 80% accuracy today', rewardExp: 150, target: 80),
    ];
    _persistMissions();
  }

  void _initDefaultMedals() {
    medals = [
      Medal(id: 'medal_started', name: '🏅 Getting Started', description: 'Answer your first question'),
      Medal(id: 'medal_combo10', name: '🔥 Combo Master', description: 'Reach 10 consecutive correct answers'),
      Medal(id: 'medal_chat10', name: '💬 Friendly Learner', description: 'Chat with AI Assistant 10 times'),
      Medal(id: 'medal_learner100', name: '🎓 Diligent Learner', description: 'Answer 100 questions'),
      Medal(id: 'medal_acc90', name: '💎 Accuracy Pro', description: 'Reach 90% accuracy overall'),
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
      _notify();
    }
  }

  void _checkMedalsAfterClaim() {
    // Getting Started: first question
    if (totalQuestions >= 1) _unlock('medal_started');
    // Diligent Learner: 100 questions
    if (totalQuestions >= 100) _unlock('medal_learner100');
    // Friendly Learner: 10 chats
    if (totalChats >= 10) _unlock('medal_chat10');
    // Accuracy Pro: accuracy >= 90%
    final acc = totalQuestions == 0 ? 0 : (correct * 100.0 / totalQuestions);
    if (acc >= 90) _unlock('medal_acc90');
    // Combo Master: 10 streak
    if (currentStreak >= 10) _unlock('medal_combo10');
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
    if (isCorrect) {
      correct++;
      currentStreak++;
    } else {
      wrong++;
      currentStreak = 0;
    }
    perSubject.putIfAbsent(subject, () => {'total': 0, 'correct': 0, 'wrong': 0});
    perSubject[subject]!['total'] = (perSubject[subject]!['total'] ?? 0) + 1;
    perSubject[subject]![isCorrect ? 'correct' : 'wrong'] = (perSubject[subject]![isCorrect ? 'correct' : 'wrong'] ?? 0) + 1;
    // Mission hooks
    // m1: Answer 20 questions today
    final m1 = todaysMissions.where((e) => e.id == 'm1').firstOrNull;
    if (m1 != null && !m1.completed) { m1.progress = (m1.progress + 1).clamp(0, m1.target); }
    // m3: Achieve 80% accuracy today -> use overall accuracy snapshot for simplicity
    final acc = totalQuestions == 0 ? 0 : (correct * 100.0 / totalQuestions).round();
    final m3 = todaysMissions.where((e) => e.id == 'm3').firstOrNull;
    if (m3 != null && !m3.completed) { m3.progress = acc.clamp(0, m3.target); m3.completed = m3.progress >= m3.target; }
    _persistMissions();
    await persistStats();
    _checkMedalsAfterClaim();
    _notify();
  }

  Future<void> recordChat() async {
    totalChats++;
    final m = todaysMissions.where((e) => e.id == 'm2').firstOrNull;
    if (m != null && !m.completed) { m.progress = (m.progress + 1).clamp(0, m.target); _persistMissions(); }
    await persistStats();
    _notify();
  }

  void _notify() {
    changeTick.value++;
  }
}

extension _SafeFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}


