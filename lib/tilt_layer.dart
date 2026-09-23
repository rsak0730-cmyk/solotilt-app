import 'package:flutter/material.dart';
import 'dart:math' as math;

class TiltLayer extends StatelessWidget {
  final double tiltX;
  final double tiltY;
  final int layerIndex;
  final List<Color> colors;

  const TiltLayer({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required this.layerIndex,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final double maxTilt = 30;
    final double normalizedTiltY = tiltY / maxTilt;
    final double normalizedTiltX = tiltX / maxTilt;
    
    // Calculate rotation and scale
    final double rotateY = normalizedTiltY * 20;
    final double rotateX = -normalizedTiltX * 20;
    final double scale = 1.05 - (layerIndex * 0.02);
    
    // Calculate blur based on tilt
    final double blurAmount = math.max(0, normalizedTiltY.abs() * 8 * (1 - layerIndex * 0.5));
    
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotateX * math.pi / 180)
            ..rotateY(rotateY * math.pi / 180)
            ..scale(scale),
          child: blurAmount > 0
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
                  child: Container(),
                )
              : Container(),
        ),
      ),
    );
  }
}
