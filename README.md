# EcoVision

EcoVision is a Flutter application for object detection using the device camera, on-screen overlays, and voice interaction.

## Features

- Real-time object detection with camera preview.
- Voice control using STT and TTS.
- Commands like `buscar [objeto]`, `buscar todo`, and `instrucciones`.
- Persistent onboarding that is played only once and includes a `Repetir instrucciones` button.
- Bluetooth support for distance/sensor data.
- Full-screen settings panel and accessibility labels for TalkBack and VoiceOver.
- Custom app icon and branded UI.

## Supported objects

- cama
- grada / gradas
- mesa
- puerta

If the user says `buscar` with an unsupported object, the app responds with `Objeto aun no incluido`.

## Requirements

- Flutter SDK
- Android Studio, Xcode, or VS Code with Flutter support
- Android or iOS device for camera, speech, and Bluetooth features

## Permissions used by the app

EcoVision requests these permissions at startup:

- Camera: required for object detection and preview.
- Location: required by Bluetooth behavior on some Android devices and for device discovery compatibility.
- Bluetooth / Nearby devices: required to search for and connect to the external Bluetooth device used by the app.
- Microphone: required for voice commands through speech recognition.

## First launch

When the app is opened for the first time, EcoVision plays a short spoken introduction. If you want to hear it again, use the `Repetir instrucciones` button on the onboarding screen before entering the camera.

## Setup

Install dependencies:

```bash
flutter pub get
```

## Run

Run on a connected device:

```bash
flutter run
```

## Useful commands

- `buscar [objeto]`: filter announcements to a specific object.
- `buscar todo`: show and announce all supported objects.
- `instrucciones`: hear the help message.
- `Repetir instrucciones`: replay the first-run onboarding message.

## Project structure

- `lib/main.dart`: main app logic, camera, voice control, and settings.
- `assets/`: logo, labels, and TFLite model.
- `test/widget_test.dart`: basic widget test.

## Notes

- Do not commit generated folders such as `build/` or `.dart_tool/`.
- Platform build artifacts and ephemeral files are ignored through `.gitignore`.
