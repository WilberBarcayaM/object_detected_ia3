//import 'dart:io';
//import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
//import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:async';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
//import 'package:image_picker/image_picker.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late FlutterVision vision;

  @override
  void initState() {
    super.initState();
    vision = FlutterVision();
    // Iniciar la detección de objetos al iniciar la aplicación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => YoloVideo(vision: vision)),
      );
    });
  }

  @override
  void dispose() async {
    super.dispose();
    await vision.closeYoloModel();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Initializing...")),
    );
  }
}

class YoloVideo extends StatefulWidget {
  final FlutterVision vision;
  const YoloVideo({Key? key, required this.vision}) : super(key: key);

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

  // Variables for Bluetooth connection and sensor data
  final _bluetooth = FlutterBluetoothSerial.instance;
  bool _bluetoothState = false;
  bool _isConnecting = false;
  BluetoothConnection? _connection;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _deviceConnected;
  String ultrasonicValue = '';
  FlutterTts flutterTts = FlutterTts();
  Timer? _timer;
  bool _isSpeakingEnabled = true;

  @override
  void initState() {
    super.initState();
    init();
    _requestPermission();
    _initBluetooth();
    _initTts();
    _startSpeakingTimer();
  }

  init() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.low);
    controller.initialize().then((value) {
      loadYoloModel().then((value) {
        setState(() {
          isLoaded = true;
          isDetecting = false;
          yoloResults = [];
        });
        startDetection();
      });
    });
  }

  void _requestPermission() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
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
  }

  void _startSpeakingTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _speakUltrasonicValue();
    });
  }

  Future<void> _speakUltrasonicValue() async {
    if (ultrasonicValue.isNotEmpty && _isSpeakingEnabled) {
      await flutterTts.speak(" $ultrasonicValue centímetros");
    }
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

  @override
  void dispose() async {
    _timer?.cancel();
    flutterTts.stop();
    _connection?.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return const Scaffold(
        body: Center(
          child: Text("Model not loaded, waiting for it"),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Sensor Ultrasónico'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(
                    controller,
                  ),
                ),
                ...displayBoxesAroundRecognizedObjects(size),
              ],
            ),
          ),
          _controlBT(),
          _infoDevice(),
          Expanded(child: _listDevices()),
          _ultrasonicDisplay(),
          _toggleSpeakingButton(),
        ],
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
    final result = await widget.vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
        detectedObject = result[0]['tag'];
        print(detectedObject);
      });
    } else {
      setState(() {
        yoloResults.clear();
      });
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
      if (isDetecting) {
        cameraImage = image;
        await yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
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
    return ListTile(
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          "Valor Ultrasónico: $ultrasonicValue cm",
          style: const TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }

  Widget _toggleSpeakingButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _isSpeakingEnabled = !_isSpeakingEnabled;
          if (_isSpeakingEnabled) {
            _startSpeakingTimer();
          } else {
            _timer?.cancel();
            flutterTts.stop();
          }
        });
      },
      child: Text(_isSpeakingEnabled ? "Desactivar voz" : "Activar voz"),
    );
  }
}
