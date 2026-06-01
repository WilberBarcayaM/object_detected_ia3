import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/constants/app_constants.dart';

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

  final _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  String ultrasonicValue = '';
  FlutterTts flutterTts = FlutterTts();
  bool _ttsInProgress = false;
  Timer? _timer;
  bool _isSpeakingEnabled = true;
  String _permissionError = '';
  String _activeSpokenObject = '';
  DateTime? _lastDetectionAt;
  bool _showControlPanel = false;
  bool mostrarPanelMicrofono = false;
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isStartingListening = false;
  Timer? _restartListeningTimer;
  String _lastRecognized = '';
  String _lastProcessedVoiceCommand = '';
  String objetoFiltrado = 'todos';
  final Set<String> _supportedObjects = <String>{
    'cama',
    'grada',
    'gradas',
    'mesa',
    'puerta',
  };
  final Map<String, String> _objectAliases = <String, String>{
    'gradas': 'grada',
  };
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

    _initBluetooth();
    _initTts();
    _initSpeech();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool onboardingCompleted =
          prefs.getBool(onboardingCompletedKey) ?? false;
      if (!onboardingCompleted) {
        final onboardingText =
            'Bienvenido a EcoVision. Puedes decir: buscar seguido del nombre del objeto para filtrar, buscar todo para ver todos los objetos, silencio para silenciar, o instrucciones para escuchar este mensaje de ayuda.';
        if (_isSpeakingEnabled) await flutterTts.speak(onboardingText);
      }
    } catch (e) {
      if (!_onboardingPlayed) {
        final onboardingText =
            'Bienvenido a EcoVision. Puedes decir: buscar seguido del nombre del objeto para filtrar, buscar todo para ver todos los objetos, silencio para silenciar, o instrucciones para escuchar este mensaje de ayuda.';
        if (_isSpeakingEnabled) await flutterTts.speak(onboardingText);
        _onboardingPlayed = true;
      }
    }
    await init();
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

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onError: (e) => print('STT init error: $e'),
      onStatus: (s) {
        print('STT status: $s');
        _handleSpeechStatus(s);
      },
    );
    setState(() {});
  }

  void _handleSpeechStatus(String status) {
    if (!mostrarPanelMicrofono || _ttsInProgress) return;
    if (status == 'done' || status == 'notListening') {
      _scheduleListeningRestart(const Duration(milliseconds: 250));
    }
  }

  void _scheduleListeningRestart(Duration delay) {
    _restartListeningTimer?.cancel();
    _restartListeningTimer = Timer(delay, () {
      if (!mounted) return;
      _startListening();
    });
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || _ttsInProgress || !mostrarPanelMicrofono) return;
    if (_isStartingListening || _speech.isListening) return;
    _isStartingListening = true;
    _lastRecognized = '';
    try {
      await _speech.listen(
        onResult: (result) async {
          final raw = result.recognizedWords;
          final text = raw.toLowerCase();
          final normalized = _normalizeText(text);
          setState(() => _lastRecognized = raw);
          if (result.finalResult) {
            print(
                'STT final recognized (raw): "$raw" normalized: "$normalized"');
            await _processVoiceCommand(normalized);
          } else {
            print('STT interim recognized: "$raw"');
            if (_isCompleteVoiceCommand(normalized)) {
              await _processVoiceCommand(normalized);
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
      _isStartingListening = false;
    }
    setState(() {});
  }

  Future<void> _stopListening() async {
    if (!_speechAvailable) return;
    _restartListeningTimer?.cancel();
    await _speech.stop();
    setState(() {});
  }

  Future<void> _toggleMic() async {
    final opening = !mostrarPanelMicrofono;
    setState(() => mostrarPanelMicrofono = opening);
    if (opening) {
      try {
        if (isDetecting) await stopDetection();
      } catch (_) {}
      _timer?.cancel();
      await _startListening();
    } else {
      _restartListeningTimer?.cancel();
      try {
        await _stopListening();
      } catch (_) {}
      try {
        if (isLoaded && !isDetecting) await startDetection();
      } catch (_) {}
      if (_isSpeakingEnabled && detectedObject.isNotEmpty) {
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
        if (_isSpeakingEnabled)
          await _speakWithPause('Detectando todos los objetos');
      } else {
        final parts = text.split('buscar');
        String candidate = parts.length > 1 ? parts[1].trim() : '';
        if (candidate.isNotEmpty) {
          final obj = _canonicalObjectName(candidate.split(' ').first);
          if (!_supportedObjects.contains(obj)) {
            if (_isSpeakingEnabled) {
              await _speakWithPause('Objeto aun no incluido');
            }
            return;
          }
          setState(() => objetoFiltrado = obj);
          if (_isSpeakingEnabled) {
            await _speakWithPause('Buscando solamente $objetoFiltrado');
          }
        }
      }
      return;
    }

    if (text.contains('instrucciones') || text.contains('ayuda')) {
      final instructions =
          'Control de voz activo. Di: buscar seguido del nombre del objeto para filtrar, buscar todo para ver todos los objetos, o instrucciones para escuchar este mensaje.';
      if (_isSpeakingEnabled) await _speakWithPause(instructions);
      return;
    }

    _lastProcessedVoiceCommand = '';
  }

  String _canonicalObjectName(String objectName) {
    final normalized = _normalizeText(objectName);
    return _objectAliases[normalized] ?? normalized;
  }

  bool _isCompleteVoiceCommand(String text) {
    if (text.isEmpty) return false;
    if (text.contains('instrucciones') || text.contains('ayuda')) return true;
    if (text.startsWith('buscar ')) {
      return text.split(' ').length >= 2;
    }
    return false;
  }

  String _normalizeText(String s) {
    final Map<String, String> map = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'Á': 'a',
      'À': 'a',
      'Ä': 'a',
      'Â': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'É': 'e',
      'È': 'e',
      'Ë': 'e',
      'Ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'Í': 'i',
      'Ì': 'i',
      'Ï': 'i',
      'Î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'Ó': 'o',
      'Ò': 'o',
      'Ö': 'o',
      'Ô': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'Ú': 'u',
      'Ù': 'u',
      'Ü': 'u',
      'Û': 'u',
      'ñ': 'n',
      'Ñ': 'n',
      ',': ' ',
      '.': ' ',
      ';': ' ',
      ':': ' ',
      '!': ' ',
      '?': ' ',
      '"': ' ',
      "'": ' '
    };
    String out = s.toLowerCase();
    map.forEach((k, v) {
      out = out.replaceAll(k, v);
    });
    out = out.replaceAll(RegExp('\\s+'), ' ').trim();
    return out;
  }

  Future<void> _speakWithPause(String phrase) async {
    if (phrase.isEmpty) return;
    final bool wasListening = _speechAvailable && _speech.isListening;
    _ttsInProgress = true;
    if (wasListening) {
      try {
        await _stopListening();
      } catch (_) {}
    }
    try {
      await flutterTts.speak(phrase);
    } catch (e) {
      print('TTS speak error: $e');
    } finally {
      _ttsInProgress = false;
      _lastProcessedVoiceCommand = '';
    }
    if (mostrarPanelMicrofono && _speechAvailable) {
      _scheduleListeningRestart(const Duration(milliseconds: 300));
    }
  }

  void _initBluetooth() {
    _bluetooth.state.then((state) {
      setState(() => _bluetoothState = state.isEnabled);
    });

    _bluetooth.onStateChanged().listen((state) {
      setState(() => _bluetoothState = state.isEnabled);
    });
  }

  void _initTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    try {
      await flutterTts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  String _buildSpokenPhrase(String objectName) {
    final bool hasDistance =
        _connection?.isConnected == true && ultrasonicValue.isNotEmpty;
    return hasDistance
        ? '$objectName a $ultrasonicValue centímetros'
        : objectName;
  }

  Future<void> _speakImmediateObject(String objectName) async {
    if (!_isSpeakingEnabled || objectName.isEmpty || mostrarPanelMicrofono) {
      return;
    }

    final String phraseToSpeak = _buildSpokenPhrase(objectName);
    _activeSpokenObject = objectName;
    _timer?.cancel();
    await flutterTts.speak(phraseToSpeak);
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || !_isSpeakingEnabled || _activeSpokenObject.isEmpty) {
        return;
      }

      await _repeatActiveObject();
    });
  }

  Future<void> _repeatActiveObject() async {
    if (!_isSpeakingEnabled ||
        _activeSpokenObject.isEmpty ||
        mostrarPanelMicrofono) {
      return;
    }

    await flutterTts.speak(_buildSpokenPhrase(_activeSpokenObject));
  }

  void _getDevices() async {
    var res = await _bluetooth.getBondedDevices();
    setState(() => _devices = res);
  }

  void _receiveData() {
    String buffer = '';
    _connection?.input?.listen((event) {
      try {
        String data = String.fromCharCodes(event);
        buffer += data;
        if (buffer.contains('\n')) {
          String value = buffer.substring(0, buffer.indexOf('\n')).trim();
          setState(() {
            ultrasonicValue = value;
          });
          buffer = '';
        }
      } catch (e) {
        print('Error handling received data: $e');
      }
    });
  }

  Future<void> _setControlPanelVisible(bool visible) async {
    if (visible == _showControlPanel) return;

    if (visible) {
      _restartListeningTimer?.cancel();
      if (mostrarPanelMicrofono) {
        setState(() {
          mostrarPanelMicrofono = false;
          _lastRecognized = '';
        });
      }
      try {
        await _stopListening();
      } catch (_) {}

      _timer?.cancel();
      _timer = null;
      _activeSpokenObject = '';
      await flutterTts.stop();

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

    if (_isSpeakingEnabled &&
        detectedObject.isNotEmpty &&
        !mostrarPanelMicrofono) {
      await _speakImmediateObject(detectedObject);
    }
  }

  @override
  void dispose() async {
    _timer?.cancel();
    _restartListeningTimer?.cancel();
    flutterTts.stop();
    _connection?.dispose();
    try {
      await _stopListening();
    } catch (_) {}
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
        appBar: AppBar(
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
              child: Stack(
                children: [
                  ...displayBoxesAroundRecognizedObjects(size),
                ],
              ),
            ),
            if (_showControlPanel) Positioned.fill(child: _buildControlPanel()),
            if (!_showControlPanel)
              Positioned(
                top: 16,
                right: 16,
                child: Semantics(
                  button: true,
                  label: 'Botón de ajustes',
                  hint: 'Abre la pantalla de ajustes',
                  child: FloatingActionButton(
                    heroTag: 'settingsFab',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    tooltip: 'Abrir ajustes',
                    onPressed: () async {
                      await _setControlPanelVisible(true);
                    },
                    child: const Icon(Icons.settings),
                  ),
                ),
              ),
            if (!_showControlPanel)
              Positioned(
                left: 16,
                bottom: 16,
                child: Semantics(
                  button: true,
                  label: 'Botón de micrófono',
                  hint: mostrarPanelMicrofono
                      ? 'Cierra el control de voz'
                      : 'Abre el control de voz',
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
                  child: FloatingActionButton.extended(
                    heroTag: 'speakFab',
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.white,
                    tooltip:
                        _isSpeakingEnabled ? 'Desactivar voz' : 'Activar voz',
                    onPressed: () {
                      setState(() {
                        _isSpeakingEnabled = !_isSpeakingEnabled;
                        if (_isSpeakingEnabled) {
                          if (detectedObject.isNotEmpty) {
                            _speakImmediateObject(detectedObject);
                          }
                        } else {
                          _timer?.cancel();
                          _timer = null;
                          _activeSpokenObject = '';
                          flutterTts.stop();
                        }
                      });
                    },
                    icon: Icon(_isSpeakingEnabled
                        ? Icons.volume_up
                        : Icons.volume_off),
                    label: Text(
                        _isSpeakingEnabled ? 'Desactivar voz' : 'Activar voz'),
                  ),
                ),
              ),
            if (!_showControlPanel)
              Positioned(
                right: 16,
                bottom: 16,
                child: Semantics(
                  button: true,
                  label: 'Botón de salir',
                  hint: 'Cierra la aplicación',
                  child: FloatingActionButton(
                    heroTag: 'exitFab',
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.white,
                    tooltip: 'Salir de la aplicación',
                    onPressed: () {
                      SystemNavigator.pop();
                    },
                    child: const Icon(Icons.exit_to_app),
                  ),
                ),
              ),
            if (mostrarPanelMicrofono)
              Positioned(
                left: 16,
                bottom: 86,
                child: Material(
                  color: Colors.transparent,
                  child: Semantics(
                    liveRegion: true,
                    label: mostrarPanelMicrofono &&
                            _speechAvailable &&
                            _speech.isListening
                        ? 'Control de voz escuchando'
                        : 'Control de voz activo',
                    value: _lastRecognized.isNotEmpty
                        ? 'Último comando: $_lastRecognized'
                        : 'Sin comando reconocido aún',
                    child: Container(
                      width: size.width * 0.9,
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
                          Icon(
                            Icons.mic,
                            size: 48,
                            color: const Color(0xFF00B4D8),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mostrarPanelMicrofono &&
                                          _speechAvailable &&
                                          _speech.isListening
                                      ? 'Escuchando...'
                                      : 'Control de voz activo. Di un comando: "Buscar [objeto]" o "Instrucciones".',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _lastRecognized.isNotEmpty
                                      ? 'Último: $_lastRecognized'
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
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      color: Colors.grey.shade100,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.black12,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Volver de ajustes',
                    onPressed: () async {
                      await _setControlPanelVisible(false);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      'Ajustes',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _controlBT(),
                    _infoDevice(),
                    _listDevices(),
                    _ultrasonicDisplay(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: const SizedBox(height: 12),
                    ),
                  ],
                ),
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
      final String selectedFilter = _canonicalObjectName(objetoFiltrado);
      final Map<String, dynamic> selectedResult = selectedFilter == 'todos'
          ? result.first
          : result.cast<Map<String, dynamic>>().firstWhere(
                (r) =>
                    _canonicalObjectName(r['tag'].toString()) == selectedFilter,
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
      if (objectName.isNotEmpty && objectName != _activeSpokenObject) {
        if (!_ttsInProgress && !mostrarPanelMicrofono) {
          await _speakImmediateObject(objectName);
        }
      } else if (objectName.isEmpty) {
        _activeSpokenObject = '';
        _timer?.cancel();
        _timer = null;
      }
    } else {
      setState(() {
        yoloResults.clear();
      });
      if (_lastDetectionAt != null &&
          DateTime.now().difference(_lastDetectionAt!) >
              const Duration(seconds: 2)) {
        detectedObject = '';
        _activeSpokenObject = '';
        _timer?.cancel();
        _timer = null;
        if (_isSpeakingEnabled && !_ttsInProgress && !mostrarPanelMicrofono) {
          flutterTts.stop();
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

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty || cameraImage == null) return [];

    double factorX = screen.width / (cameraImage!.height);
    double factorY = screen.height / (cameraImage!.width);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _controlBT() {
    return SwitchListTile(
      value: _bluetoothState,
      onChanged: (bool value) async {
        if (value) {
          await _bluetooth.requestEnable();
        } else {
          await _bluetooth.requestDisable();
        }
      },
      tileColor: Colors.black26,
      title:
          Text(_bluetoothState ? "Bluetooth encendido" : "Bluetooth apagado"),
    );
  }

  Widget _infoDevice() {
    return ListTile(
      tileColor: Colors.black12,
      title: Text("Conectado a: ${_deviceConnected?.name ?? "ninguno"}"),
      trailing: _connection?.isConnected ?? false
          ? TextButton(
              onPressed: () async {
                await _connection?.finish();
                setState(() => _deviceConnected = null);
              },
              child: const Text("Desconectar"),
            )
          : TextButton(
              onPressed: _getDevices,
              child: const Text("Ver dispositivos"),
            ),
    );
  }

  Widget _listDevices() {
    return _isConnecting
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: _devices
                    .map((device) => ListTile(
                          title: Text(device.name ?? device.address),
                          trailing: TextButton(
                            child: const Text('Conectar'),
                            onPressed: () async {
                              setState(() => _isConnecting = true);
                              _connection = await BluetoothConnection.toAddress(
                                  device.address);
                              _deviceConnected = device;
                              _devices = [];
                              _isConnecting = false;
                              _receiveData();
                              setState(() {});
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          );
  }

  Widget _ultrasonicDisplay() {
    final String distanceText =
        ultrasonicValue.isNotEmpty ? '$ultrasonicValue cm' : '—';
    final String objectText = detectedObject.isNotEmpty ? detectedObject : '—';
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Objeto: $objectText',
              style:
                  const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Distancia: $distanceText',
              style: const TextStyle(fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleSpeakingButton() {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _isSpeakingEnabled = !_isSpeakingEnabled;
          if (_isSpeakingEnabled) {
            if (detectedObject.isNotEmpty) {
              _speakImmediateObject(detectedObject);
            }
          } else {
            _timer?.cancel();
            _timer = null;
            _activeSpokenObject = '';
            flutterTts.stop();
          }
        });
      },
      icon: Icon(
        _isSpeakingEnabled ? Icons.volume_off : Icons.volume_up,
        size: 20,
      ),
      label: Text(_isSpeakingEnabled ? 'Desactivar voz' : 'Activar voz'),
    );
  }
}
