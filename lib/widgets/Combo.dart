import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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

  final List<double> fontSizes = [24, 26, 28, 30, 34, 38, 42];

  int comboCount = 0;
  int levelIndex = 0;
  double progress = 0.0;
  Timer? decayTimer;

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
      setState(() {
        double minProgress = 0.25 * levelIndex; // 当前等级下限
        progress -= 0.01;
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
      progress += 0.25;
      double levelMax = 0.25 * (levelIndex + 1);
      if (progress >= levelMax) {
        if (levelIndex < comboLevels.length - 1) levelIndex++;
        progress = 0.0;
      }
    });

    // 播放音效
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
      comboCount = 0;
      levelIndex = 0;
      progress = 0.0;
    });
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
              return Transform.rotate(
                angle: rotate,
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    comboLevels[levelIndex],
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
