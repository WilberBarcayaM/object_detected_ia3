#include <SoftwareSerial.h>
#include <Ultrasonic.h>

// Definir pines para el sensor ultrasónico (Trig, Echo)
Ultrasonic sensor(5, 6);

// Definir pines para SoftwareSerial (Arduino RX, Arduino TX)
SoftwareSerial bt(2, 3); // Pin 2 conecta al TX del HC-05, Pin 3 al RX del HC-05

void setup() {
  // Inicializar la comunicación serial hardware (USB)
  Serial.begin(9600);
  
  // Inicializar la comunicación serial para el módulo Bluetooth
  bt.begin(9600); // Velocidad de comunicación: 9600 bits por segundo

  // Mensaje inicial para verificar que el setup se ha ejecutado
  Serial.println("Setup completo. Comenzando mediciones...");
  bt.println("Setup completo. Comenzando mediciones...");
}

void loop() {
  // Leer la distancia del sensor ultrasónico en cm
  int distancia = sensor.read();

  // Filtrar lecturas válidas dentro del rango (hasta 3.5 metros)
  if (distancia > 0 && distancia < 350) {
    // Enviar la distancia a través de Bluetooth
    bt.println(distancia);
    
    // También enviar la distancia a través de la consola serial para depuración
    Serial.println("Distancia: " + String(distancia) + " cm");
  } else {
    // Enviar mensaje de fuera de rango para depuración
    Serial.println("Distancia fuera de rango");
  }

  // Espera 200 milisegundos antes de tomar otra lectura
  delay(200);
}
