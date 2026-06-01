import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class OnboardingScreen extends StatefulWidget {
  final Future<void> Function() onContinue;

  const OnboardingScreen({super.key, required this.onContinue});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  static const String _onboardingText =
      'Bienvenido. Esta es la primera vez que abres EcoVision. '
      'Primero escucharás estas instrucciones y luego entrarás a la cámara. '
      'Cuando ya estés dentro de la app, podrás usar el botón de micrófono para decir comandos como buscar seguido del objeto o instrucciones.';

  @override
  void initState() {
    super.initState();
    _playInstructions();
  }

  Future<void> _playInstructions() async {
    try {
      await _tts.setLanguage('es-ES');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      if (!mounted) return;
      setState(() => _speaking = true);
      await _tts.speak(_onboardingText);
    } finally {
      if (mounted) {
        setState(() => _speaking = false);
      }
    }
  }

  Future<void> _repeatInstructions() async {
    if (_speaking) {
      await _tts.stop();
    }
    await _playInstructions();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/logoEcoVision.jpg',
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'EcoVision',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Primera vez en la app',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF00B4D8),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Espera un momento. La app te explicará cómo usarla antes de mostrar la cámara.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Luego podrás usar: buscar [objeto], buscar todo e instrucciones.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 17,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_speaking)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00B4D8),
                          ),
                        )
                      else ...[
                        ElevatedButton(
                          onPressed: _repeatInstructions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: const Color(0xFF00B4D8),
                            side: const BorderSide(
                                color: Color(0xFF00B4D8), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Repetir instrucciones',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await widget.onContinue();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4D8),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Continuar a la cámara',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
