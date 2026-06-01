import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool ttsInProgress = false;
  Timer? _timer;
  bool isSpeakingEnabled = true;
  String activeSpokenObject = '';

  Future<void> init() async {
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await _tts.speak(text);
    } catch (e) {
      print('TTS error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
  }

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resetActiveObject() {
    activeSpokenObject = '';
  }

  Future<void> speakImmediateObject({
    required String objectName,
    required String Function(String) phraseBuilder,
    required bool Function() shouldMute,
  }) async {
    if (!isSpeakingEnabled || objectName.isEmpty || shouldMute()) {
      return;
    }

    final String phraseToSpeak = phraseBuilder(objectName);
    activeSpokenObject = objectName;
    cancelTimer();
    await speak(phraseToSpeak);

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (isSpeakingEnabled && activeSpokenObject.isNotEmpty && !shouldMute()) {
        await speak(phraseBuilder(activeSpokenObject));
      }
    });
  }

  void dispose() {
    cancelTimer();
    _tts.stop();
  }
}
