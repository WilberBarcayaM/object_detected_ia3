import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum SettingsSubView {
  main,
  conexion,
  objetos,
  sensorState,
}

class ControlPanelWidget extends StatefulWidget {
  final bool bluetoothState;
  final bool isConnected;
  final bool isConnecting;
  final BluetoothDevice? deviceConnected;
  final List<BluetoothDevice> devices;
  final String ultrasonicValue;
  final String detectedObject;
  final String objetoFiltrado;

  final VoidCallback onBackPressed;
  final ValueChanged<bool> onBluetoothStateChanged;
  final VoidCallback onDisconnectPressed;
  final VoidCallback onGetDevicesPressed;
  final ValueChanged<BluetoothDevice> onConnectToDevice;
  final ValueChanged<String> onObjectSelected;

  const ControlPanelWidget({
    super.key,
    required this.bluetoothState,
    required this.isConnected,
    required this.isConnecting,
    required this.deviceConnected,
    required this.devices,
    required this.ultrasonicValue,
    required this.detectedObject,
    required this.objetoFiltrado,
    required this.onBackPressed,
    required this.onBluetoothStateChanged,
    required this.onDisconnectPressed,
    required this.onGetDevicesPressed,
    required this.onConnectToDevice,
    required this.onObjectSelected,
  });

  @override
  State<ControlPanelWidget> createState() => _ControlPanelWidgetState();
}

class _ControlPanelWidgetState extends State<ControlPanelWidget> {
  SettingsSubView _currentSubView = SettingsSubView.main;

  @override
  Widget build(BuildContext context) {
    String title;
    switch (_currentSubView) {
      case SettingsSubView.main:
        title = 'Ajustes';
        break;
      case SettingsSubView.conexion:
        title = 'Conexión';
        break;
      case SettingsSubView.objetos:
        title = 'Seleccionar objeto';
        break;
      case SettingsSubView.sensorState:
        title = 'Estado del Sensor';
        break;
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Cabecera con fondo blanco y sombra inferior
            Material(
              elevation: 3.0,
              shadowColor: Colors.black.withOpacity(0.4),
              color: Colors.white,
              child: Container(
                height: 56.0,
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: _currentSubView == SettingsSubView.main
                          ? 'Volver a la cámara'
                          : 'Volver a Ajustes',
                      onPressed: () {
                        if (_currentSubView == SettingsSubView.main) {
                          widget.onBackPressed();
                        } else {
                          setState(() {
                            _currentSubView = SettingsSubView.main;
                          });
                        }
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentSubView) {
      case SettingsSubView.main:
        return _buildMainView();
      case SettingsSubView.conexion:
        return _buildConexionView();
      case SettingsSubView.objetos:
        return _buildObjetosView();
      case SettingsSubView.sensorState:
        return _buildSensorStateView();
    }
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildMainOptionTile(
            title: 'Conexión',
            icon: Icons.bluetooth,
            onTap: () {
              setState(() {
                _currentSubView = SettingsSubView.conexion;
              });
            },
          ),
          _buildMainOptionTile(
            title: 'Seleccionar objeto',
            icon: Icons.category,
            onTap: () {
              setState(() {
                _currentSubView = SettingsSubView.objetos;
              });
            },
          ),
          _buildMainOptionTile(
            title: 'Estado del sensor',
            icon: Icons.sensors,
            onTap: () {
              setState(() {
                _currentSubView = SettingsSubView.sensorState;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainOptionTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.black54,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF00B4D8),
          size: 24.0,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildConexionView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _controlBT(),
          _infoDevice(),
          _listDevices(),
        ],
      ),
    );
  }

  Widget _buildObjetosView() {
    final List<Map<String, dynamic>> items = [
      {'name': 'Todos los objetos', 'value': 'todos', 'icon': Icons.all_inclusive},
      {'name': 'Cama', 'value': 'cama', 'icon': Icons.bed},
      {'name': 'Gradas', 'value': 'grada', 'icon': Icons.stairs},
      {'name': 'Mesa', 'value': 'mesa', 'icon': Icons.table_restaurant},
      {'name': 'Puerta', 'value': 'puerta', 'icon': Icons.meeting_room},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String value = item['value'] as String;
        final bool isSelected = widget.objetoFiltrado == value;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: ListTile(
            leading: Icon(
              item['icon'] as IconData,
              color: isSelected ? const Color(0xFF00B4D8) : Colors.black54,
            ),
            title: Text(
              item['name'] as String,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00B4D8) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 16.0,
              ),
            ),
            trailing: isSelected
                ? const Icon(
                    Icons.check,
                    color: Color(0xFF00B4D8),
                  )
                : null,
            onTap: () {
              widget.onObjectSelected(value);
            },
          ),
        );
      },
    );
  }

  Widget _buildSensorStateView() {
    final String distanceText =
        widget.ultrasonicValue.isNotEmpty ? '${widget.ultrasonicValue} cm' : '—';
    final String objectText = widget.detectedObject.isNotEmpty ? widget.detectedObject : '—';
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.visibility,
              color: Colors.black54,
            ),
            title: Text(
              'Objeto detectado: $objectText',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.straighten,
              color: Colors.black54,
            ),
            title: Text(
              'Distancia: $distanceText',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlBT() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: SwitchListTile(
        activeColor: const Color(0xFF00B4D8),
        activeTrackColor: const Color(0xFF00B4D8).withOpacity(0.38),
        secondary: Icon(
          widget.bluetoothState ? Icons.bluetooth : Icons.bluetooth_disabled,
          color: widget.bluetoothState ? const Color(0xFF00B4D8) : Colors.black38,
        ),
        value: widget.bluetoothState,
        onChanged: widget.onBluetoothStateChanged,
        title: Text(
          widget.bluetoothState ? "Bluetooth encendido" : "Bluetooth apagado",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _infoDevice() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          widget.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_searching,
          color: widget.isConnected ? const Color(0xFF00B4D8) : Colors.black38,
        ),
        title: Text(
          "Conectado a: ${widget.deviceConnected?.name ?? "ninguno"}",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: widget.isConnected
            ? TextButton(
                onPressed: widget.onDisconnectPressed,
                child: const Text(
                  "Desconectar",
                  style: TextStyle(color: Colors.redAccent),
                ),
              )
            : TextButton(
                onPressed: widget.onGetDevicesPressed,
                child: const Text(
                  "Ver dispositivos",
                  style: TextStyle(color: Color(0xFF00B4D8)),
                ),
              ),
      ),
    );
  }

  Widget _listDevices() {
    if (widget.isConnecting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
        ),
      );
    }
    if (widget.devices.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: widget.devices
            .map((device) => Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black12,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.black38),
                    title: Text(
                      device.name ?? device.address,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => widget.onConnectToDevice(device),
                      child: const Text('Conectar'),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
