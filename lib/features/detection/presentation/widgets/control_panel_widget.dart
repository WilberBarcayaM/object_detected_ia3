import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ControlPanelWidget extends StatelessWidget {
  final bool bluetoothState;
  final bool isConnected;
  final bool isConnecting;
  final BluetoothDevice? deviceConnected;
  final List<BluetoothDevice> devices;
  final String ultrasonicValue;
  final String detectedObject;

  final VoidCallback onBackPressed;
  final ValueChanged<bool> onBluetoothStateChanged;
  final VoidCallback onDisconnectPressed;
  final VoidCallback onGetDevicesPressed;
  final ValueChanged<BluetoothDevice> onConnectToDevice;

  const ControlPanelWidget({
    super.key,
    required this.bluetoothState,
    required this.isConnected,
    required this.isConnecting,
    required this.deviceConnected,
    required this.devices,
    required this.ultrasonicValue,
    required this.detectedObject,
    required this.onBackPressed,
    required this.onBluetoothStateChanged,
    required this.onDisconnectPressed,
    required this.onGetDevicesPressed,
    required this.onConnectToDevice,
  });

  @override
  Widget build(BuildContext context) {
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
                    onPressed: onBackPressed,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Text(
                      'Ajustes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: SizedBox(height: 12),
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

  Widget _controlBT() {
    return SwitchListTile(
      value: bluetoothState,
      onChanged: onBluetoothStateChanged,
      tileColor: Colors.black26,
      title: Text(bluetoothState ? "Bluetooth encendido" : "Bluetooth apagado"),
    );
  }

  Widget _infoDevice() {
    return ListTile(
      tileColor: Colors.black12,
      title: Text("Conectado a: ${deviceConnected?.name ?? "ninguno"}"),
      trailing: isConnected
          ? TextButton(
              onPressed: onDisconnectPressed,
              child: const Text("Desconectar"),
            )
          : TextButton(
              onPressed: onGetDevicesPressed,
              child: const Text("Ver dispositivos"),
            ),
    );
  }

  Widget _listDevices() {
    return isConnecting
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                children: devices
                    .map((device) => ListTile(
                          title: Text(device.name ?? device.address),
                          trailing: TextButton(
                            child: const Text('Conectar'),
                            onPressed: () => onConnectToDevice(device),
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
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
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
}
