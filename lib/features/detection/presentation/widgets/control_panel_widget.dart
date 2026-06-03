import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

enum SettingsSubView {
  main,
  conexion,
  objetos,
  sensorState,
  faq,
  armado,
  codigoArduino,
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
      case SettingsSubView.armado:
        title = 'Guía de armado para el hardware';
        break;
      case SettingsSubView.codigoArduino:
        title = 'Código de Arduino';
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
                        } else if (_currentSubView ==
                            SettingsSubView.codigoArduino) {
                          setState(() {
                            _currentSubView = SettingsSubView.armado;
                          });
                        } else {
                          setState(() {
                            _currentSubView = SettingsSubView.main;
                          });
                        }
                      },
                      child: IconButton(
                        tooltip: _currentSubView == SettingsSubView.main
                            ? 'Volver a la cámara'
                            : (_currentSubView == SettingsSubView.codigoArduino
                                ? 'Volver a Guía de armado para el hardware'
                                : 'Volver a Ajustes'),
                        onPressed: () {
                          if (_currentSubView == SettingsSubView.main) {
                            widget.onBackPressed();
                          } else if (_currentSubView ==
                              SettingsSubView.codigoArduino) {
                            setState(() {
                              _currentSubView = SettingsSubView.armado;
                            });
                          } else {
                            setState(() {
                              _currentSubView = SettingsSubView.main;
                            });
                          }
                        },
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.black87),
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
      case SettingsSubView.armado:
        return _buildArmadoView();
      case SettingsSubView.codigoArduino:
        return _buildCodigoArduinoView();
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
            title: 'Guía de armado para el hardware',
            icon: Icons.build,
            onTap: () {
              setState(() {
                _currentSubView = SettingsSubView.armado;
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

  Widget _buildArmadoView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('1. Componentes requeridos'),
          _buildComponentCard(
            title: 'Arduino Uno',
            description:
                'Placa microcontroladora principal que procesa las lecturas del sensor y las envía al celular.',
            imagePath: 'assets/images/hardware/arduino-uno.jpg',
          ),
          _buildComponentCard(
            title: 'Sensor Ultrasónico HC-SR04',
            description:
                'Sensor que emite ondas de sonido para calcular la distancia a los obstáculos más cercanos.',
            imagePath: 'assets/images/hardware/sensor-ultrasonico.jpg',
          ),
          _buildComponentCard(
            title: 'Módulo Bluetooth HC-05',
            description:
                'Módulo de transmisión serial inalámbrico que comunica el Arduino con el celular.',
            imagePath: 'assets/images/hardware/modulo-bluetooth.jpg',
          ),
          _buildComponentCard(
            title: 'Protoboard pequeña',
            description:
                'Placa de pruebas para conectar cables y distribuir la alimentación de 5V entre los componentes.',
            imagePath: 'assets/images/hardware/protoboard.jpg',
          ),
          _buildComponentCard(
            title: 'Batería de 9V y Conector',
            description:
                'Batería portátil y clip Jack para alimentar de forma autónoma la placa de Arduino Uno.',
            imagePath:
                'assets/images/hardware/bateria-conector-alimentacion.jpg',
          ),
          _buildComponentCard(
            title: 'Cables Jumpers',
            description:
                'Cables de conexión tipo macho-macho y macho-hembra para interconectar los pines entre Arduino, protoboard y los módulos.',
            imagePath: 'assets/images/hardware/cables-jumpers.jpg',
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('2. Distribución de energía (5V)'),
          _buildInstructionStep(
            'Paso 1: Alimentación protoboard',
            'Conecta un cable desde el único pin de 5V del Arduino al riel positivo (línea roja con el símbolo +) de la protoboard.',
          ),
          _buildInstructionStep(
            'Paso 2: Módulo Bluetooth VCC',
            'Conecta el pin VCC del módulo Bluetooth HC-05 a cualquier pin del riel positivo + de la protoboard.',
          ),
          _buildInstructionStep(
            'Paso 3: Sensor Ultrasónico VCC',
            'Conecta el pin VCC del sensor ultrasónico a cualquier pin del riel positivo + de la protoboard.',
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('3. Conexiones a tierra (GND)'),
          _buildInstructionStep(
            'Paso 4: Bluetooth GND',
            'Conecta el pin GND del módulo Bluetooth HC-05 directamente a uno de los pines GND del Arduino.',
          ),
          _buildInstructionStep(
            'Paso 5: Sensor Ultrasónico GND',
            'Conecta el pin GND del sensor ultrasónico directamente a otro de los pines GND del Arduino.',
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('4. Conexiones de datos'),
          _buildInstructionStep(
            'Paso 6: Bluetooth TX/RX',
            'Conecta el pin TXD del módulo Bluetooth al pin digital 2 del Arduino. Conecta el pin RXD del módulo al pin digital 3 del Arduino.',
          ),
          _buildInstructionStep(
            'Paso 7: Sensor Trig/Echo',
            'Conecta el pin Trig del sensor al pin digital 5 del Arduino. Conecta el pin Echo del sensor al pin digital 6 del Arduino.',
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('5. Montaje y uso portátil'),
          _buildInstructionStep(
            'Paso 8: Alimentación',
            'Conecta la batería de 9V al Jack de alimentación del Arduino para que funcione de forma autónoma.',
          ),
          _buildInstructionStep(
            'Paso 9: Acople al teléfono',
            'Introduce el circuito en una caja plástica (dejando el sensor descubierto al frente) y ajústala en la parte superior del celular apuntando al frente, alineado con la cámara trasera.',
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('6. Código de programación'),
          _buildInstructionStep(
            'Código de Arduino',
            'El código de Arduino que debes subir a tu placa se encuentra disponible en el repositorio de GitHub de este proyecto (carpeta arduino/eco_vision_sensor/). Puedes visualizarlo aquí y copiarlo a tu portapapeles tocando el botón de abajo:',
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            excludeSemantics: true,
            label: 'Ver código de Arduino',
            hint:
                'Toca dos veces para ver el código fuente que se debe cargar en la placa Arduino',
            onTap: () {
              setState(() {
                _currentSubView = SettingsSubView.codigoArduino;
              });
            },
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4D8),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  _currentSubView = SettingsSubView.codigoArduino;
                });
              },
              icon: const Icon(Icons.code),
              label: const Text('Ver código de Arduino'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCodigoArduinoView() {
    const String arduinoCode = '''#include <SoftwareSerial.h>
#include <Ultrasonic.h>

// Definir pines para el sensor ultrasónico (Trig, Echo)
Ultrasonic sensor(5, 6);

// Definir pines para SoftwareSerial (Arduino RX, Arduino TX)
SoftwareSerial bt(2, 3); // Pin 2 al TX del HC-05, Pin 3 al RX del HC-05

void setup() {
  Serial.begin(9600);
  bt.begin(9600);
  Serial.println("Setup completo. Comenzando mediciones...");
  bt.println("Setup completo. Comenzando mediciones...");
}

void loop() {
  int distancia = sensor.read();

  if (distancia > 0 && distancia < 350) {
    bt.println(distancia);
    Serial.println("Distancia: " + String(distancia) + " cm");
  } else {
    Serial.println("Distancia fuera de rango");
  }

  delay(200);
}''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Puedes copiar este código al portapapeles de tu celular para transferirlo a tu computadora o IDE de Arduino:',
            style: TextStyle(color: Colors.black87, fontSize: 14.5),
          ),
          const SizedBox(height: 12),
          Semantics(
            button: true,
            excludeSemantics: true,
            label: 'Copiar código de Arduino',
            hint:
                'Toca dos veces para copiar el código de programación en el portapapeles de tu celular',
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: arduinoCode));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Código copiado al portapapeles'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4D8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: arduinoCode));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código copiado al portapapeles'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar código'),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
            child: const SelectableText(
              arduinoCode,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.0,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00B4D8),
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(color: Colors.black87, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, fontSize: 15.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String stepTitle, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stepTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 15.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqView() {
    final List<Map<String, String>> faqs = [
      {
        'q': '¿Qué es EcoVision y cuál es su objetivo?',
        'a':
            'EcoVision es una aplicación de asistencia diseñada para personas con discapacidad visual. Utiliza la cámara del teléfono y un sensor ultrasónico externo para detectar objetos comunes en el entorno (como camas, gradas, mesas y puertas) y anunciar su presencia y distancia por medio de audio (síntesis de voz).'
      },
      {
        'q': '¿Cómo funciona la medición de distancia y el sensor ultrasónico?',
        'a':
            'La aplicación se conecta mediante Bluetooth a un dispositivo de medición externo (un módulo Bluetooth HC-05 acoplado a un sensor de distancia ultrasónico). El sensor mide los centímetros de distancia hasta el objeto de frente y la aplicación te lo dice con voz natural: si supera el metro dirá "cama a 1 metro con 15 centímetros", y si es menor dirá "mesa a 40 centímetros".'
      },
      {
        'q': '¿Qué objetos puede identificar la aplicación actualmente?',
        'a':
            'La inteligencia artificial de la aplicación está entrenada específicamente para reconocer cuatro objetos críticos de navegación en el hogar: camas, gradas (escaleras), mesas y puertas. Puedes elegir buscar uno en específico o activar la detección de todos de forma simultánea.'
      },
      {
        'q':
            '¿Por qué mi módulo de Bluetooth (por ejemplo, HC-05) no aparece al presionar "Ver dispositivos"?',
        'a':
            'Por motivos de seguridad y rendimiento, la aplicación solo lista dispositivos que ya han sido vinculados (emparejados) previamente en los Ajustes del sistema de tu celular. Si no aparece, abre la configuración de Bluetooth de tu teléfono, vincula el dispositivo ingresando su clave (normalmente 1234 o 0000), y luego regresa a EcoVision para conectarlo con un solo toque.'
      },
      {
        'q': '¿Cómo utilizo el control por comandos de voz?',
        'a':
            'En la parte inferior izquierda de la pantalla de la cámara, presiona el botón de micrófono. Se abrirá un panel que escuchará tus comandos. Puedes decir órdenes en español como: "buscar cama", "buscar gradas", "buscar todo", o "instrucciones". Si el comando u objeto es válido, la app se configurará y cerrará el micrófono automáticamente para evitar interferencias.'
      },
      {
        'q':
            '¿Admite plurales el control por voz (por ejemplo, "buscar gradas" o "buscar camas")?',
        'a':
            'Sí. El sistema de procesamiento de voz de la aplicación está optimizado para normalizar el habla. Interpreta de la misma manera términos en singular o plural, como "grada/gradas", "cama/camas", "mesa/mesas" y "puerta/puertas", facilitando su uso intuitivo.'
      },
      {
        'q':
            '¿Puedo desactivar temporalmente el audio explicativo de los objetos detectados?',
        'a':
            'Sí. En la parte inferior central tienes el botón Desactivar voz / Activar voz. Al presionarlo, silenciarás las alertas auditivas en tiempo real de los objetos que capta la cámara, permitiéndote navegar de forma silenciosa o usar únicamente el lector de pantalla.'
      },
      {
        'q':
            '¿Cómo puedo volver a escuchar las instrucciones de ayuda si las olvido?',
        'a':
            'Puedes hacerlo fácilmente de dos maneras:\n1. Abre el control de voz presionando el botón de micrófono en la pantalla principal y di la palabra "instrucciones" o "ayuda".\n2. Consulta la guía en la sección de ajustes. La aplicación reproducirá nuevamente el mensaje con la explicación de los comandos de voz y los objetos que puedes buscar.'
      },
      {
        'q':
            '¿EcoVision es totalmente compatible con TalkBack y lectores de pantalla?',
        'a':
            'Sí, la interfaz de usuario se ha optimizado para lectores de pantalla. Todos los botones flotantes y los paneles de ajustes cuentan con etiquetas de accesibilidad completas en español (Semantics) y zonas de enfoque separadas. Además, se desactivó la semántica visual de los cuadros de detección de YOLO (ExcludeSemantics) para evitar que TalkBack se trabe al intentar enfocar dinámicamente los recuadros de la cámara.'
      },
      {
        'q':
            '¿Requiere la aplicación una conexión activa a Internet para funcionar?',
        'a':
            'No. Toda la inferencia de inteligencia artificial (detección YOLOv8), el motor de comandos de voz, la lectura Bluetooth y la síntesis de voz (TTS) se ejecutan de manera local e interna en tu dispositivo. Esto garantiza un funcionamiento rápido, privado y 100% disponible en cualquier lugar, sin gastar datos móviles.'
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
      {
        'name': 'Todos los objetos',
        'value': 'todos',
        'icon': Icons.all_inclusive
      },
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
    final String distanceText = widget.ultrasonicValue.isNotEmpty
        ? '${widget.ultrasonicValue} cm'
        : '—';
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
          color:
              widget.bluetoothState ? const Color(0xFF00B4D8) : Colors.black38,
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
          widget.isConnected
              ? Icons.bluetooth_connected
              : Icons.bluetooth_searching,
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

  Widget _buildComponentCard({
    required String title,
    required String description,
    required String imagePath,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                imagePath,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade100,
                    child:
                        const Icon(Icons.broken_image, color: Colors.black38),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
