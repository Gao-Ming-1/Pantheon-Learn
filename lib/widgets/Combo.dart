import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/audio_service.dart';

class ComboWidget extends StatefulWidget {
  const ComboWidget({super.key});

  @override
  ComboWidgetState createState() => ComboWidgetState();
}

class ComboWidgetState extends State<ComboWidget> with TickerProviderStateMixin {
  final List<String> comboLevels = [
    "D——Dismal",
    "C——Crazy",
    "B——Badass",
    "A——Apocalyptic",
    "S——Savage!",
    "SS——Sick skills!!",
    "SSS——Smokin' sexy style!!!"
  ];

  final List<Color> baseColors = [
    Colors.grey,
    Colors.cyan,
    Colors.lightBlue,
    Colors.orange,
    Colors.red,
    Colors.purpleAccent,
    Colors.yellowAccent,
  ];

  final List<double> fontSizes = [18, 20, 22, 24, 26, 28, 30];

  int comboCount = 0;
  int levelIndex = 0;
  double progress = 0.0;
  Timer? decayTimer;
  bool paused = false; // 外部可暂停衰减

  // 可调参数（默认用于 Olevel/PSLE English）
  double decayStep = 0.01;        // 每 tick 衰减
  double correctIncD = 0.58;      // D 等级每次增加
  double correctIncOther = 0.25;  // 其它等级每次增加
  double wrongDec = 0.30;         // 答错减少

  late AudioPlayer audioPlayer;

  late AnimationController textAnimController;
  late AnimationController particleController;
  List<_Particle> particles = [];

  final int particleCount = 20;
  final double particleMaxDistance = 50;

  @override
  void initState() {
    super.initState();

    audioPlayer = AudioPlayer();
    AudioService.instance.init();

    textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        setState(() {});
      });

    decayTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (paused) return;
      setState(() {
        double minProgress = 0.25 * levelIndex; // 当前等级下限
        progress -= decayStep;
        if (progress < minProgress) {
          if (levelIndex > 0) levelIndex--;
          progress = minProgress;
        }
      });
    });
  }

  @override
  void dispose() {
    decayTimer?.cancel();
    textAnimController.dispose();
    particleController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  void onAnswerCorrect() {
    setState(() {
      comboCount++;
      // 可调：D 等级、其它等级使用不同增量
      final double inc = (levelIndex == 0) ? correctIncD : correctIncOther;
      progress = (progress + inc).clamp(0.0, 1.0);

      // 根据进度定位等级（按 0.25 分段）
      int targetLevel = (progress / 0.25).floor();
      if (targetLevel >= comboLevels.length) targetLevel = comboLevels.length - 1;
      levelIndex = targetLevel;
    });

    // 播放音效
    audioPlayer.setVolume(AudioService.instance.volume01);
    audioPlayer.play(AssetSource('audio/combo_level_$levelIndex.mp3'));

    // 文字动画
    textAnimController.forward(from: 0.0);

    // 粒子动画
    particles = List.generate(particleCount, (_) => _Particle(
      offset: Offset.zero,
      velocity: Offset(Random().nextDouble()*2-1, Random().nextDouble()*-1.5-0.5)*particleMaxDistance,
      color: baseColors[levelIndex],
      size: Random().nextDouble()*4+2,
    ));
    particleController.forward(from: 0.0);
  }

  void onAnswerWrong() {
    setState(() {
      // 可调：整体进度减少比例
      progress = (progress - wrongDec).clamp(0.0, 1.0);
      int targetLevel = (progress / 0.25).floor();
      if (targetLevel >= comboLevels.length) targetLevel = comboLevels.length - 1;
      levelIndex = targetLevel;
      if (progress == 0.0) comboCount = 0;
    });
  }

  void reset() {
    onAnswerWrong();
  }

  void setPaused(bool value) {
    paused = value;
  }

  // 外部设置难度参数（用于非英语科目调整）
  void setTuning({double? decayStep, double? correctIncD, double? correctIncOther, double? wrongDec}) {
    if (decayStep != null) this.decayStep = decayStep;
    if (correctIncD != null) this.correctIncD = correctIncD;
    if (correctIncOther != null) this.correctIncOther = correctIncOther;
    if (wrongDec != null) this.wrongDec = wrongDec;
  }

  Color _getGradientColor(double t, Color start, Color end) {
    return Color.lerp(start, end, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 粒子效果
          ...particles.map((p) {
            double t = particleController.value;
            return Positioned(
              left: 120 + p.velocity.dx * t,
              top: 60 + p.velocity.dy * t,
              child: Opacity(
                opacity: 1-t,
                child: Container(
                  width: p.size,
                  height: p.size,
                  decoration: BoxDecoration(
                    color: p.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }).toList(),

          // 连击文字
          AnimatedBuilder(
            animation: textAnimController,
            builder: (context, child) {
              double scale = 1.0 + 0.5 * textAnimController.value;
              double rotate = 0.1 * textAnimController.value;
              Color color = _getGradientColor(comboCount/10, baseColors[levelIndex], Colors.white);
              return Opacity(
                opacity: 0.7,
                child: Transform.rotate(
                  angle: rotate,
                  child: Transform.scale(
                    scale: scale,
                  child: Text(
                    comboLevels[levelIndex],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSizes[levelIndex],
                      fontWeight: FontWeight.bold,
                      color: color,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.white, offset: Offset(2,2))
                      ],
                    ),
                  ),
                  ),
                ),
              );
            },
          ),

          // 进度条
          Positioned(
            bottom: 12,
            child: Container(
              width: 200,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[700],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: baseColors[levelIndex],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  Offset offset;
  Offset velocity;
  Color color;
  double size;
  _Particle({required this.offset, required this.velocity, required this.color, required this.size});
}
