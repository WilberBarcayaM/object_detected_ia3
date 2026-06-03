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
  static const String _onboardingText =
      'Bienvenido. Esta es la primera vez que abres EcoVision. '
      'Primero escucharás estas instrucciones y luego entrarás a la cámara. '
      'Para que la aplicación funcione correctamente, asegúrate de otorgar los permisos de cámara, micrófono, ubicación y bluetooth cuando tu celular te los solicite. '
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
      await _tts.speak(_onboardingText);
    } catch (e) {
      // Ignorar errores de TTS durante inicialización
    }
  }

  Future<void> _repeatInstructions() async {
    await _tts.stop();
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
                          semanticLabel: 'Logo de EcoVision',
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: const Text(
                          'EcoVision',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: const Text(
                          'Primera vez en la app',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF00B4D8),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Card de Instrucciones de Uso
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00B4D8).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.info_outline, color: Color(0xFF00B4D8), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Instrucciones de Uso',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Escucha las instrucciones de voz. Al ingresar a la cámara principal, podrás controlar la aplicación por voz diciendo comandos como:',
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            _buildInstructionBullet('buscar [objeto]', 'Para buscar algo en específico (ej. "buscar silla")'),
                            _buildInstructionBullet('buscar todo', 'Para detectar cualquier objeto en el entorno'),
                            _buildInstructionBullet('instrucciones / ayuda', 'Para escuchar las indicaciones nuevamente'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        button: true,
                        label: 'Continuar a la cámara principal',
                        hint: 'Cierra las instrucciones e inicia el detector de objetos',
                        child: ElevatedButton(
                          onPressed: () async {
                            await _tts.stop();
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
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        button: true,
                        label: 'Repetir instrucciones de voz',
                        hint: 'Vuelve a reproducir las instrucciones de audio de la aplicación',
                        child: ElevatedButton(
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
                      ),
                      const SizedBox(height: 24),
                      // Card de Permisos Requeridos
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00B4D8).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.security, color: Color(0xFF00B4D8), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Permisos Requeridos',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Para el correcto funcionamiento de EcoVision, deberás otorgar los siguientes permisos en la siguiente pantalla:',
                              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            _buildPermissionRow(
                              icon: Icons.camera_alt_outlined,
                              title: 'Cámara (Obligatorio)',
                              desc: 'Requerido para procesar el entorno y detectar los objetos por imagen.',
                            ),
                            _buildPermissionRow(
                              icon: Icons.mic_none_outlined,
                              title: 'Micrófono',
                              desc: 'Requerido para el reconocimiento de tus comandos de voz de búsqueda.',
                            ),
                            _buildPermissionRow(
                              icon: Icons.bluetooth_outlined,
                              title: 'Bluetooth y Ubicación',
                              desc: 'Requerido para conectar la app al bastón inteligente y medir distancias.',
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildInstructionBullet(String command, String explanation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Color(0xFF00B4D8), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
                children: [
                  TextSpan(
                    text: '"$command": ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B4D8)),
                  ),
                  TextSpan(
                    text: explanation,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF00B4D8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
