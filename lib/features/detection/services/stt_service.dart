import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool speechAvailable = false;
  bool isStartingListening = false;
  Timer? _restartListeningTimer;

  bool get isListening => _speech.isListening;

  Future<void> init({
    required Function(String status) onStatus,
    required Function(dynamic error) onError,
  }) async {
    speechAvailable = await _speech.initialize(
      onError: (e) => onError(e),
      onStatus: (s) => onStatus(s),
    );
  }

  void cancelRestartTimer() {
    _restartListeningTimer?.cancel();
    _restartListeningTimer = null;
  }

  void scheduleListeningRestart({
    required Duration delay,
    required bool Function() shouldRestart,
    required Future<void> Function() restartAction,
  }) {
    cancelRestartTimer();
    _restartListeningTimer = Timer(delay, () async {
      if (shouldRestart()) {
        await restartAction();
      }
    });
  }

  Future<void> startListening({
    required Function(String rawText) onResultReceived,
    required Function(String normalizedText, bool isFinal) onCommandRecognized,
    required String Function(String) textNormalizer,
    required bool Function(String) isCompleteCommandChecker,
    required bool Function() shouldAbort,
  }) async {
    if (!speechAvailable || shouldAbort()) return;
    if (isStartingListening || _speech.isListening) return;

    isStartingListening = true;
    try {
      await _speech.listen(
        onResult: (result) async {
          final raw = result.recognizedWords;
          final text = raw.toLowerCase();
          final normalized = textNormalizer(text);

          onResultReceived(raw);

          if (result.finalResult) {
            print('STT final recognized (raw): "$raw" normalized: "$normalized"');
            await onCommandRecognized(normalized, true);
          } else {
            print('STT interim recognized: "$raw"');
            if (isCompleteCommandChecker(normalized)) {
              await onCommandRecognized(normalized, false);
            }
          }
        },
        localeId: 'es_ES',
        cancelOnError: true,
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      );
    } finally {
      isStartingListening = false;
    }
  }

  Future<void> stopListening() async {
    cancelRestartTimer();
    if (!speechAvailable) return;
    await _speech.stop();
  }

  void dispose() {
    cancelRestartTimer();
    _speech.stop();
  }
}
