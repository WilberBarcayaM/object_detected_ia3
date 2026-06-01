import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../services/bluetooth_service.dart';
import '../services/stt_service.dart';
import '../services/tts_service.dart';
import '../services/voice_command_processor.dart';
import 'widgets/bounding_boxes_overlay.dart';
import 'widgets/control_panel_widget.dart';
import 'widgets/voice_control_panel_widget.dart';

late List<CameraDescription> cameras;

class YoloVideo extends StatefulWidget {
  final FlutterVision vision;
  const YoloVideo({super.key, required this.vision});

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late CameraController controller;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  String detectedObject = "";

  late final BluetoothService _bluetoothService;
  late final TtsService _ttsService;
  late final SttService _sttService;

  bool _bluetoothState = false;
  bool _isConnecting = false;
  List<BluetoothDevice> _devices = [];
  String ultrasonicValue = '';
  bool _showControlPanel = false;
  bool mostrarPanelMicrofono = false;
  String _permissionError = '';
  DateTime? _lastDetectionAt;
  String _lastRecognized = '';
  String _lastProcessedVoiceCommand = '';
  String objetoFiltrado = 'todos';
  bool _onboardingPlayed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _requestPermission();

    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      if (!mounted) return;
      setState(() {
        _permissionError = 'Camera permission denied';
      });
      return;
    }

    _initBluetoothService();
    _initTtsService();
    _initSttService();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool onboardingCompleted =
          prefs.getBool(onboardingCompletedKey) ?? false;
      if (!onboardingCompleted) {
        const onboardingText =
            'Bienvenido a EcoVision. Puedes decir: buscar seguido del nombre del objeto para filtrar, buscar todo para ver todos los objetos, o instrucciones para escuchar este mensaje de ayuda.';
        if (_ttsService.isSpeakingEnabled) {
          await _ttsService.speak(onboardingText);
        }
      }
    } catch (e) {
      if (!_onboardingPlayed) {
        const onboardingText =
            'Bienvenido a EcoVision. Puedes decir: buscar seguido del nombre del objeto para filtrar, buscar todo para ver todos los objetos, o instrucciones para escuchar este mensaje de ayuda.';
        if (_ttsService.isSpeakingEnabled) {
          await _ttsService.speak(onboardingText);
        }
        _onboardingPlayed = true;
      }
    }
    await init();
  }

  void _initBluetoothService() {
    _bluetoothService = BluetoothService(
      onStateChanged: (isEnabled) {
        if (!mounted) return;
        setState(() {
          _bluetoothState = isEnabled;
        });
      },
      onDataReceived: (value) {
        if (!mounted) return;
        setState(() {
          ultrasonicValue = value;
        });
      },
      onConnectionChanged: (device) {
        if (!mounted) return;
        setState(() {
          if (device == null) {
            _devices = [];
          }
        });
      },
    );
    _bluetoothService.init();
  }

  void _initTtsService() {
    _ttsService = TtsService();
    _ttsService.init();
  }

  void _initSttService() {
    _sttService = SttService();
    _sttService.init(
      onStatus: (s) {
        print('STT status: $s');
        _handleSpeechStatus(s);
      },
      onError: (e) {
        print('STT init error: $e');
      },
    );
  }

  init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.low);
    await controller.initialize();
    await loadYoloModel();
    setState(() {
      isLoaded = true;
      isDetecting = false;
      yoloResults = [];
    });
    startDetection();
  }

  Future<void> _requestPermission() async {
    await Permission.camera.request();
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.microphone.request();
  }

  void _handleSpeechStatus(String status) {
    if (!mostrarPanelMicrofono || _ttsService.ttsInProgress) return;
    if (status == 'done' || status == 'notListening') {
      _sttService.scheduleListeningRestart(
        delay: const Duration(milliseconds: 250),
        shouldRestart: () => mounted && mostrarPanelMicrofono,
        restartAction: _startListening,
      );
    }
  }

  Future<void> _startListening() async {
    await _sttService.startListening(
      onResultReceived: (rawText) {
        if (!mounted) return;
        setState(() {
          _lastRecognized = rawText;
        });
      },
      onCommandRecognized: (normalizedText, isFinal) async {
        if (isFinal) {
          await _processVoiceCommand(normalizedText);
        } else {
          if (VoiceCommandProcessor.isCompleteVoiceCommand(normalizedText)) {
            await _processVoiceCommand(normalizedText);
          }
        }
      },
      textNormalizer: VoiceCommandProcessor.normalizeText,
      isCompleteCommandChecker: VoiceCommandProcessor.isCompleteVoiceCommand,
      shouldAbort: () => _ttsService.ttsInProgress || !mostrarPanelMicrofono,
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleMic() async {
    final opening = !mostrarPanelMicrofono;
    setState(() => mostrarPanelMicrofono = opening);
    if (opening) {
      try {
        if (isDetecting) await stopDetection();
      } catch (_) {}
      _ttsService.cancelTimer();
      await _startListening();
    } else {
      _sttService.cancelRestartTimer();
      try {
        await _sttService.stopListening();
      } catch (_) {}
      try {
        if (isLoaded && !isDetecting) await startDetection();
      } catch (_) {}
      if (_ttsService.isSpeakingEnabled && detectedObject.isNotEmpty) {
        await _speakImmediateObject(detectedObject);
      }
    }
  }

  Future<void> _processVoiceCommand(String text) async {
    if (text.isEmpty) return;
    if (text == _lastProcessedVoiceCommand) return;
    _lastProcessedVoiceCommand = text;
    print('Processing voice command: "$text"');
    if (text.contains('buscar')) {
      if (text.contains('todo') || text.contains('ver todo')) {
        setState(() => objetoFiltrado = 'todos');
        if (_ttsService.isSpeakingEnabled) {
          await _speakWithPause('Detectando todos los objetos');
        }
        await _toggleMic();
      } else {
        final parts = text.split('buscar');
        String candidate = parts.length > 1 ? parts[1].trim() : '';
        if (candidate.isNotEmpty) {
          final obj = VoiceCommandProcessor.canonicalObjectName(
              candidate.split(' ').first);
          if (!VoiceCommandProcessor.supportedObjects.contains(obj)) {
            if (_ttsService.isSpeakingEnabled) {
              await _speakWithPause('Objeto aun no incluido');
            }
            return;
          }
          setState(() => objetoFiltrado = obj);
          if (_ttsService.isSpeakingEnabled) {
            await _speakWithPause('Buscando solamente $objetoFiltrado');
          }
          await _toggleMic();
        }
      }
      return;
    }

    if (text.contains('instrucciones') || text.contains('ayuda')) {
      const instructions =
          'Control de voz activo. Di: buscar seguido del nombre del objeto para filtrar, buscar todo para ver todos los objetos, o instrucciones para escuchar este mensaje.';
      if (_ttsService.isSpeakingEnabled) await _speakWithPause(instructions);
      return;
    }

    _lastProcessedVoiceCommand = '';
  }

  Future<void> _speakWithPause(String phrase) async {
    if (phrase.isEmpty) return;
    final bool wasListening =
        _sttService.speechAvailable && _sttService.isListening;
    _ttsService.ttsInProgress = true;
    if (wasListening) {
      try {
        await _sttService.stopListening();
      } catch (_) {}
    }
    try {
      await _ttsService.speak(phrase);
    } catch (e) {
      print('TTS speak error: $e');
    } finally {
      _ttsService.ttsInProgress = false;
      _lastProcessedVoiceCommand = '';
    }
    if (mostrarPanelMicrofono && _sttService.speechAvailable) {
      _sttService.scheduleListeningRestart(
        delay: const Duration(milliseconds: 300),
        shouldRestart: () => mounted && mostrarPanelMicrofono,
        restartAction: _startListening,
      );
    }
  }

  String _buildSpokenPhrase(String objectName) {
    final bool hasDistance =
        _bluetoothService.isConnected && ultrasonicValue.isNotEmpty;
    if (!hasDistance) return objectName;

    final int? cm = int.tryParse(ultrasonicValue);
    if (cm == null) return '$objectName a $ultrasonicValue centímetros';

    if (cm < 100) {
      final String cmText = cm == 1 ? '1 centímetro' : '$cm centímetros';
      return '$objectName a $cmText';
    } else {
      final int meters = cm ~/ 100;
      final int remainingCm = cm % 100;

      final String metersText = meters == 1 ? '1 metro' : '$meters metros';
      if (remainingCm == 0) {
        return '$objectName a $metersText';
      } else {
        final String cmText =
            remainingCm == 1 ? '1 centímetro' : '$remainingCm centímetros';
        return '$objectName a $metersText con $cmText';
      }
    }
  }

  Future<void> _speakImmediateObject(String objectName) async {
    await _ttsService.speakImmediateObject(
      objectName: objectName,
      phraseBuilder: _buildSpokenPhrase,
      shouldMute: () => !mounted || mostrarPanelMicrofono,
    );
  }

  Future<void> _setControlPanelVisible(bool visible) async {
    if (visible == _showControlPanel) return;

    if (visible) {
      _sttService.cancelRestartTimer();
      if (mostrarPanelMicrofono) {
        setState(() {
          mostrarPanelMicrofono = false;
          _lastRecognized = '';
        });
      }
      try {
        await _sttService.stopListening();
      } catch (_) {}

      _ttsService.cancelTimer();
      _ttsService.resetActiveObject();
      await _ttsService.stop();

      try {
        await stopDetection();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _showControlPanel = true;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _showControlPanel = false;
    });

    try {
      if (isLoaded && !isDetecting) await startDetection();
    } catch (_) {}

    if (_ttsService.isSpeakingEnabled &&
        detectedObject.isNotEmpty &&
        !mostrarPanelMicrofono) {
      await _speakImmediateObject(detectedObject);
    }
  }

  @override
  void dispose() {
    _ttsService.dispose();
    _bluetoothService.dispose();
    _sttService.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionError.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Image.asset(
            'assets/logoEcoVision.jpg',
            height: 34,
            fit: BoxFit.contain,
            semanticLabel: 'EcoVision',
          ),
        ),
        body: Center(
          child: Text(_permissionError),
        ),
      );
    }

    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Cargando modelo..."),
        ),
      );
    }
    return PopScope(
      canPop: !_showControlPanel && !mostrarPanelMicrofono,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_showControlPanel) {
          await _setControlPanelVisible(false);
          return;
        }
        if (mostrarPanelMicrofono) {
          await _toggleMic();
        }
      },
      child: Scaffold(
        appBar: _showControlPanel
            ? null
            : AppBar(
                centerTitle: true,
                title: Image.asset(
                  'assets/logoEcoVision.jpg',
                  height: 34,
                  fit: BoxFit.contain,
                ),
              ),
        body: Stack(
          children: [
            Positioned.fill(
              child: CameraPreview(controller),
            ),
            Positioned.fill(
              child: BoundingBoxesOverlay(
                yoloResults: yoloResults,
                screenSize: size,
                cameraImageHeight: cameraImage?.height ?? 0,
                cameraImageWidth: cameraImage?.width ?? 0,
              ),
            ),
            if (!_showControlPanel &&
                _bluetoothService.isConnected &&
                ultrasonicValue.isNotEmpty)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Distancia: $ultrasonicValue cm',
                      style: const TextStyle(
                        color: Color(0xFF00B4D8),
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            if (!_showControlPanel)
              Positioned(
                left: 16,
                bottom: 16,
                child: Semantics(
                  button: true,
                  excludeSemantics: true,
                  label: mostrarPanelMicrofono
                      ? 'Cerrar control de voz'
                      : 'Abrir control de voz',
                  hint: 'Toca dos veces para ' +
                      (mostrarPanelMicrofono ? 'cerrar' : 'abrir') +
                      ' el panel de micrófono y control de voz',
                  onTap: () async {
                    await _toggleMic();
                  },
                  child: FloatingActionButton(
                    heroTag: 'micFab',
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.white,
                    tooltip: mostrarPanelMicrofono
                        ? 'Cerrar control de voz'
                        : 'Abrir control de voz',
                    onPressed: () async {
                      await _toggleMic();
                    },
                    child: Icon(
                      mostrarPanelMicrofono ? Icons.close : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (!_showControlPanel)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: Semantics(
                    button: true,
                    excludeSemantics: true,
                    label: _ttsService.isSpeakingEnabled
                        ? 'Desactivar voz'
                        : 'Activar voz',
                    hint: 'Toca dos veces para ' +
                        (_ttsService.isSpeakingEnabled
                            ? 'silenciar'
                            : 'activar') +
                        ' la lectura de voz de objetos detectados',
                    onTap: () {
                      setState(() {
                        _ttsService.isSpeakingEnabled =
                            !_ttsService.isSpeakingEnabled;
                        if (_ttsService.isSpeakingEnabled) {
                          if (detectedObject.isNotEmpty) {
                            _speakImmediateObject(detectedObject);
                          }
                        } else {
                          _ttsService.cancelTimer();
                          _ttsService.resetActiveObject();
                          _ttsService.stop();
                        }
                      });
                    },
                    child: FloatingActionButton.extended(
                      heroTag: 'speakFab',
                      backgroundColor: const Color(0xFF00B4D8),
                      foregroundColor: Colors.white,
                      tooltip: _ttsService.isSpeakingEnabled
                          ? 'Desactivar voz'
                          : 'Activar voz',
                      onPressed: () {
                        setState(() {
                          _ttsService.isSpeakingEnabled =
                              !_ttsService.isSpeakingEnabled;
                          if (_ttsService.isSpeakingEnabled) {
                            if (detectedObject.isNotEmpty) {
                              _speakImmediateObject(detectedObject);
                            }
                          } else {
                            _ttsService.cancelTimer();
                            _ttsService.resetActiveObject();
                            _ttsService.stop();
                          }
                        });
                      },
                      icon: Icon(_ttsService.isSpeakingEnabled
                          ? Icons.volume_up
                          : Icons.volume_off),
                      label: Text(_ttsService.isSpeakingEnabled
                          ? 'Desactivar voz'
                          : 'Activar voz'),
                    ),
                  ),
                ),
              ),
            if (!_showControlPanel)
              Positioned(
                right: 16,
                bottom: 16,
                child: Semantics(
                  button: true,
                  excludeSemantics: true,
                  label: 'Ajustes',
                  hint: 'Toca dos veces para abrir la pantalla de ajustes y configuración de Bluetooth',
                  onTap: () async {
                    await _setControlPanelVisible(true);
                  },
                  child: FloatingActionButton(
                    heroTag: 'settingsFab',
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.white,
                    tooltip: 'Abrir ajustes',
                    onPressed: () async {
                      await _setControlPanelVisible(true);
                    },
                    child: const Icon(Icons.settings, color: Colors.white),
                  ),
                ),
              ),
            if (mostrarPanelMicrofono)
              Positioned(
                left: 16,
                bottom: 86,
                child: VoiceControlPanelWidget(
                  width: size.width * 0.9,
                  isListening: _sttService.isListening,
                  speechAvailable: _sttService.speechAvailable,
                  lastRecognized: _lastRecognized,
                ),
              ),
            if (_showControlPanel)
              Positioned.fill(
                child: ControlPanelWidget(
                  bluetoothState: _bluetoothState,
                  isConnected: _bluetoothService.isConnected,
                  isConnecting: _isConnecting,
                  deviceConnected: _bluetoothService.deviceConnected,
                  devices: _devices,
                  ultrasonicValue: ultrasonicValue,
                  detectedObject: detectedObject,
                  objetoFiltrado: objetoFiltrado,
                  onBackPressed: () async {
                    await _setControlPanelVisible(false);
                  },
                  onBluetoothStateChanged: (bool value) async {
                    if (value) {
                      await _bluetoothService.enable();
                    } else {
                      await _bluetoothService.disable();
                    }
                  },
                  onDisconnectPressed: () async {
                    await _bluetoothService.disconnect();
                    setState(() {});
                  },
                  onGetDevicesPressed: () async {
                    final res = await _bluetoothService.getBondedDevices();
                    setState(() {
                      _devices = res;
                    });
                  },
                  onConnectToDevice: (device) async {
                    setState(() => _isConnecting = true);
                    try {
                      await _bluetoothService.connectToDevice(device);
                    } catch (_) {}
                    setState(() {
                      _devices = [];
                      _isConnecting = false;
                    });
                  },
                  onObjectSelected: (value) {
                    setState(() {
                      objetoFiltrado = value;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
        labels: 'assets/labels.txt',
        modelPath: 'assets/model.tflite',
        modelVersion: "yolov8",
        numThreads: 6,
        useGpu: true);
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    if (!isDetecting || _showControlPanel) return;
    final result = await widget.vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (!mounted || !isDetecting || _showControlPanel) return;
    if (result.isNotEmpty) {
      final String selectedFilter =
          VoiceCommandProcessor.canonicalObjectName(objetoFiltrado);
      final Map<String, dynamic> selectedResult = selectedFilter == 'todos'
          ? result.first
          : result.cast<Map<String, dynamic>>().firstWhere(
                (r) =>
                    VoiceCommandProcessor.canonicalObjectName(
                        r['tag'].toString()) ==
                    selectedFilter,
                orElse: () => <String, dynamic>{},
              );
      final bool hasTarget = selectedResult.isNotEmpty;
      final String objectName =
          hasTarget ? selectedResult['tag'].toString() : '';
      setState(() {
        yoloResults = result;
        detectedObject = objectName;
        print(detectedObject);
      });
      _lastDetectionAt = DateTime.now();
      if (objectName.isNotEmpty &&
          objectName != _ttsService.activeSpokenObject) {
        if (!_ttsService.ttsInProgress && !mostrarPanelMicrofono) {
          await _speakImmediateObject(objectName);
        }
      } else if (objectName.isEmpty) {
        _ttsService.resetActiveObject();
        _ttsService.cancelTimer();
      }
    } else {
      setState(() {
        yoloResults.clear();
      });
      if (_lastDetectionAt != null &&
          DateTime.now().difference(_lastDetectionAt!) >
              const Duration(seconds: 2)) {
        detectedObject = '';
        _ttsService.resetActiveObject();
        _ttsService.cancelTimer();
        if (_ttsService.isSpeakingEnabled &&
            !_ttsService.ttsInProgress &&
            !mostrarPanelMicrofono) {
          _ttsService.stop();
        }
      }
    }
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (isDetecting && !_showControlPanel) {
        cameraImage = image;
        await yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}

    setState(() {
      isDetecting = false;
      yoloResults.clear();
      detectedObject = '';
      _lastDetectionAt = null;
    });
  }
}
