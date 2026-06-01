import 'package:flutter/material.dart';

class BoundingBoxesOverlay extends StatelessWidget {
  final List<Map<String, dynamic>> yoloResults;
  final Size screenSize;
  final int cameraImageHeight;
  final int cameraImageWidth;

  const BoundingBoxesOverlay({
    super.key,
    required this.yoloResults,
    required this.screenSize,
    required this.cameraImageHeight,
    required this.cameraImageWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (yoloResults.isEmpty || cameraImageHeight == 0 || cameraImageWidth == 0) {
      return const SizedBox.shrink();
    }

    double factorX = screenSize.width / cameraImageHeight;
    double factorY = screenSize.height / cameraImageWidth;

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);

    return ExcludeSemantics(
      child: Stack(
        children: yoloResults.map((result) {
          final box = result["box"];
          if (box == null || box.length < 5) return const SizedBox.shrink();

          double left = box[0] * factorX;
          double top = box[1] * factorY;
          double width = (box[2] - box[0]) * factorX;
          double height = (box[3] - box[1]) * factorY;

          return Positioned(
            left: left,
            top: top,
            width: width,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                border: Border.all(color: Colors.pink, width: 2.0),
              ),
              child: Text(
                "${result['tag']} ${(box[4] * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  background: Paint()..color = colorPick,
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
