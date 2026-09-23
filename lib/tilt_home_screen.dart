import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'tilt_layer.dart';

class TiltHomeScreen extends StatefulWidget {
  const TiltHomeScreen({super.key});

  @override
  State<TiltHomeScreen> createState() => _TiltHomeScreenState();
}

class _TiltHomeScreenState extends State<TiltHomeScreen> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    // For iOS 13+, permission is requested automatically by sensors_plus
    setState(() {
      _permissionGranted = true;
    });
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    setState(() {
      _tiltX = event.x.clamp(-30, 30);
      _tiltY = event.y.clamp(-30, 30);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gyroscope listener
          StreamBuilder<GyroscopeEvent>(
            stream: gyroscopeEventStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData && _permissionGranted) {
                _onGyroscopeEvent(snapshot.data!);
              }
              return Container();
            },
          ),
          
          // Tilt layers
          TiltLayer(
            tiltX: _tiltX,
            tiltY: _tiltY,
            layerIndex: 0,
            colors: const [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          TiltLayer(
            tiltX: _tiltX,
            tiltY: _tiltY,
            layerIndex: 1,
            colors: const [Color(0xFFf093fb), Color(0xFFf5576c)],
          ),
          
          // Permission prompt
          if (!_permissionGranted)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Enable Motion Sensors',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _requestPermission,
                      child: const Text('Grant Permission'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
