import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../features/detection/presentation/yolo_video.dart';
import '../../features/onboarding/onboarding_screen.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  FlutterVision? vision;
  bool _loading = true;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      vision = FlutterVision();
    }
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted =
        prefs.getBool(onboardingCompletedKey) ?? false;
    if (!mounted) return;
    setState(() {
      _showOnboarding = !onboardingCompleted;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00B4D8)),
        ),
      );
    }

    if (_showOnboarding) {
      return OnboardingScreen(
        onContinue: () async {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool(onboardingCompletedKey, true);
          if (!mounted) return;
          setState(() {
            _showOnboarding = false;
          });
        },
      );
    }

    if (vision == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'La cámara solo está disponible en Android e iOS.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return YoloVideo(vision: vision!);
  }
}
