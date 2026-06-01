import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  final _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  bool isConnecting = false;

  final Function(bool isEnabled)? onStateChanged;
  final Function(String data)? onDataReceived;
  final Function(BluetoothDevice? device)? onConnectionChanged;

  BluetoothDevice? deviceConnected;

  BluetoothService({
    this.onStateChanged,
    this.onDataReceived,
    this.onConnectionChanged,
  });

  bool get isConnected => _connection?.isConnected ?? false;

  void init() {
    _bluetooth.state.then((state) {
      onStateChanged?.call(state.isEnabled);
    });

    _bluetooth.onStateChanged().listen((state) {
      onStateChanged?.call(state.isEnabled);
    });
  }

  Future<void> enable() async {
    await _bluetooth.requestEnable();
  }

  Future<void> disable() async {
    await _bluetooth.requestDisable();
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await _bluetooth.getBondedDevices();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    isConnecting = true;
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      deviceConnected = device;
      onConnectionChanged?.call(deviceConnected);
      _receiveData();
    } catch (e) {
      print('Bluetooth connection error: $e');
      deviceConnected = null;
      onConnectionChanged?.call(null);
      rethrow;
    } finally {
      isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.finish();
    } catch (e) {
      print('Error closing bluetooth connection: $e');
    }
    _connection = null;
    deviceConnected = null;
    onConnectionChanged?.call(null);
  }

  void _receiveData() {
    String buffer = '';
    _connection?.input?.listen((event) {
      try {
        String data = String.fromCharCodes(event);
        buffer += data;
        if (buffer.contains('\n')) {
          String value = buffer.substring(0, buffer.indexOf('\n')).trim();
          onDataReceived?.call(value);
          buffer = '';
        }
      } catch (e) {
        print('Error handling received data: $e');
      }
    }, onDone: () {
      _connection = null;
      deviceConnected = null;
      onConnectionChanged?.call(null);
    });
  }

  void dispose() {
    _connection?.dispose();
  }
}
