import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum SettingsSubView {
  main,
  conexion,
  objetos,
  sensorState,
  faq,
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
      case SettingsSubView.faq:
        title = 'Preguntas frecuentes';
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
                    Semantics(
                      container: true,
                      button: true,
                      excludeSemantics: true,
                      label: _currentSubView == SettingsSubView.main
                          ? 'Volver a la cámara'
                          : 'Volver a Ajustes',
                      onTap: () {
                        if (_currentSubView == SettingsSubView.main) {
                          widget.onBackPressed();
                        } else {
                          setState(() {
                            _currentSubView = SettingsSubView.main;
                          });
                        }
                      },
                      child: IconButton(
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
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      container: true,
                      header: true,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
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
      case SettingsSubView.faq:
        return _buildFaqView();
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
          _buildMainOptionTile(
            title: 'Preguntas frecuentes',
            icon: Icons.help_outline,
            onTap: () {
              setState(() {
                _currentSubView = SettingsSubView.faq;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFaqView() {
    final List<Map<String, String>> faqs = [
      {
        'q': '¿Qué es EcoVision y cuál es su objetivo?',
        'a': 'EcoVision es una aplicación de asistencia diseñada para personas con discapacidad visual. Utiliza la cámara del teléfono y un sensor ultrasónico externo para detectar objetos comunes en el entorno (como camas, gradas, mesas y puertas) y anunciar su presencia y distancia por medio de audio (síntesis de voz).'
      },
      {
        'q': '¿Cómo funciona la medición de distancia y el sensor ultrasónico?',
        'a': 'La aplicación se conecta mediante Bluetooth a un dispositivo de medición externo (un módulo Bluetooth HC-05 acoplado a un sensor de distancia ultrasónico). El sensor mide los centímetros de distancia hasta el objeto de frente y la aplicación te lo dice con voz natural: si supera el metro dirá "cama a 1 metro con 15 centímetros", y si es menor dirá "mesa a 40 centímetros".'
      },
      {
        'q': '¿Qué objetos puede identificar la aplicación actualmente?',
        'a': 'La inteligencia artificial de la aplicación está entrenada específicamente para reconocer cuatro objetos críticos de navegación en el hogar: camas, gradas (escaleras), mesas y puertas. Puedes elegir buscar uno en específico o activar la detección de todos de forma simultánea.'
      },
      {
        'q': '¿Por qué mi módulo de Bluetooth (por ejemplo, HC-05) no aparece al presionar "Ver dispositivos"?',
        'a': 'Por motivos de seguridad y rendimiento, la aplicación solo lista dispositivos que ya han sido vinculados (emparejados) previamente en los Ajustes del sistema de tu celular. Si no aparece, abre la configuración de Bluetooth de tu teléfono, vincula el dispositivo ingresando su clave (normalmente 1234 o 0000), y luego regresa a EcoVision para conectarlo con un solo toque.'
      },
      {
        'q': '¿Cómo utilizo el control por comandos de voz?',
        'a': 'En la parte inferior izquierda de la pantalla de la cámara, presiona el botón de micrófono. Se abrirá un panel que escuchará tus comandos. Puedes decir órdenes en español como: "buscar cama", "buscar gradas", "buscar todo", o "instrucciones". Si el comando u objeto es válido, la app se configurará y cerrará el micrófono automáticamente para evitar interferencias.'
      },
      {
        'q': '¿Admite plurales el control por voz (por ejemplo, "buscar gradas" o "buscar camas")?',
        'a': 'Sí. El sistema de procesamiento de voz de la aplicación está optimizado para normalizar el habla. Interpreta de la misma manera términos en singular o plural, como "grada/gradas", "cama/camas", "mesa/mesas" y "puerta/puertas", facilitando su uso intuitivo.'
      },
      {
        'q': '¿Puedo desactivar temporalmente el audio explicativo de los objetos detectados?',
        'a': 'Sí. En la parte inferior central tienes el botón Desactivar voz / Activar voz. Al presionarlo, silenciarás las alertas auditivas en tiempo real de los objetos que capta la cámara, permitiéndote navegar de forma silenciosa o usar únicamente el lector de pantalla.'
      },
      {
        'q': '¿Cómo puedo volver a escuchar las instrucciones de ayuda si las olvido?',
        'a': 'Puedes hacerlo fácilmente de dos maneras:\n1. Abre el control de voz presionando el botón de micrófono en la pantalla principal y di la palabra "instrucciones" o "ayuda".\n2. Consulta la guía en la sección de ajustes. La aplicación reproducirá nuevamente el mensaje con la explicación de los comandos de voz y los objetos que puedes buscar.'
      },
      {
        'q': '¿EcoVision es totalmente compatible con TalkBack y lectores de pantalla?',
        'a': 'Sí, la interfaz de usuario se ha optimizado para lectores de pantalla. Todos los botones flotantes y los paneles de ajustes cuentan con etiquetas de accesibilidad completas en español (Semantics) y zonas de enfoque separadas. Además, se desactivó la semántica visual de los cuadros de detección de YOLO (ExcludeSemantics) para evitar que TalkBack se trabe al intentar enfocar dinámicamente los recuadros de la cámara.'
      },
      {
        'q': '¿Requiere la aplicación una conexión activa a Internet para funcionar?',
        'a': 'No. Toda la inferencia de inteligencia artificial (detección YOLOv8), el motor de comandos de voz, la lectura Bluetooth y la síntesis de voz (TTS) se ejecutan de manera local e interna en tu dispositivo. Esto garantiza un funcionamiento rápido, privado y 100% disponible en cualquier lugar, sin gastar datos móviles.'
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24.0),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
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
          child: ExpansionTile(
            collapsedIconColor: Colors.black54,
            iconColor: const Color(0xFF00B4D8),
            title: Text(
              faq['q']!,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                child: Text(
                  faq['a']!,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15.0,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
