import 'package:flutter/material.dart';

import 'view/app_root.dart';

class EcoVisionApp extends StatelessWidget {
  const EcoVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AppRoot(),
    );
  }
}
