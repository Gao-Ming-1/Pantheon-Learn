import 'package:text_to_speech/text_to_speech.dart';

class TtsService {
  TtsService._internal();
  static final TtsService instance = TtsService._internal();

  final TextToSpeech _tts = TextToSpeech();
  bool _inited = false;

  void _ensureInit() {
    if (_inited) return;
    _tts.setLanguage('en-US');
    _tts.setRate(1.0);
    _tts.setVolume(1.0);
    _inited = true;
  }

  void speak(String text) {
    if (text.trim().isEmpty) return;
    _ensureInit();
    _tts.speak(text);
  }

  void stop() {
    _tts.stop();
  }
}


