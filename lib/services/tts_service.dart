import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _inited = false;

  static Future<void> _ensureInit() async {
    if (_inited) return;
    // 基本配置：英文优先，速率与音量适中
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    final bool isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final bool isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (isIOS) {
      await _tts.setSharedInstance(true);
      // ignore: deprecated_member_use
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    } else if (isAndroid) {
      // 让系统选择默认引擎，避免因设备缺少 Google TTS 导致失败
    }
    _inited = true;
  }

  static Future<void> speakWord(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInit();
    // 仅朗读字母/空格/常见符号，避免读出无意义字符
    // 使用双引号的原始字符串，避免在字符类中转义单引号问题
    final safe = text.replaceAll(RegExp(r"[^A-Za-z\s\-'/]"), '');
    final toSpeak = kIsWeb ? text : (safe.isEmpty ? text : safe);
    try {
      await _tts.stop();
      await _tts.speak(toSpeak);
    } catch (_) {}
  }
}


