import 'package:flutter/material.dart';

class VoiceControlPanelWidget extends StatelessWidget {
  final double width;
  final bool isListening;
  final bool speechAvailable;
  final String lastRecognized;

  const VoiceControlPanelWidget({
    super.key,
    required this.width,
    required this.isListening,
    required this.speechAvailable,
    required this.lastRecognized,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Semantics(
        liveRegion: true,
        label: isListening && speechAvailable
            ? 'Control de voz escuchando'
            : 'Control de voz activo',
        value: lastRecognized.isNotEmpty
            ? 'Último comando: $lastRecognized'
            : 'Sin comando reconocido aún',
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF00B4D8), width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.mic,
                size: 48,
                color: Color(0xFF00B4D8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isListening && speechAvailable
                          ? 'Escuchando...'
                          : 'Control de voz activo. Di un comando: "Buscar [objeto]" o "Instrucciones".',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lastRecognized.isNotEmpty
                          ? 'Último: $lastRecognized'
                          : '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
