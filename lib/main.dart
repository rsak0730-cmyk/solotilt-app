import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const SoloTiltApp());
}

class SoloTiltApp extends StatelessWidget {
  const SoloTiltApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solo Tilt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const TiltScreen(),
    );
  }
}

class TiltScreen extends StatefulWidget {
  const TiltScreen({super.key});

  @override
  State<TiltScreen> createState() => _TiltScreenState();
}

class _TiltScreenState extends State<TiltScreen> {
  int _preset = 0;

  final List<List<Color>> _presets = [
    [
      Color(0xFF667EEA),
      Color(0xFF764BA2),
    ],
    [
      Color(0xFFF093FB),
      Color(0xFFF5576C),
    ],
    [
      Color(0xFF4FACFE),
      Color(0xFF00F2FE),
    ],
    [
      Color(0xFF43E97B),
      Color(0xFF38F9D7),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<GyroscopeEvent>(
        stream: gyroscopeEventStream(),
        builder: (context, snapshot) {
          double x = 0;
          double y = 0;

          if (snapshot.hasData) {
            x = snapshot.data!.x.clamp(-5.0, 5.0);
            y = snapshot.data!.y.clamp(-5.0, 5.0);
          }

          return Stack(
            children: [
              Positioned.fill(
                child: _buildTiltBackground(x, y),
              ),

              Positioned(
                top: 35,
                right: 12,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _showPresets,
                  ),
                ),
              ),

              const Positioned(
                left: 0,
                right: 0,
                bottom: 35,
                child: SafeArea(
                  child: Center(
                    child: Text(
                      'SOLO TILT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTiltBackground(double x, double y) {
    final normalizedX = (x / 5).clamp(-1.0, 1.0);
    final normalizedY = (y / 5).clamp(-1.0, 1.0);

    final rotationX =
        -normalizedY * 0.12;

    final rotationY =
        normalizedX * 0.12;

    final scale =
        1.08 +
        (normalizedX.abs() + normalizedY.abs()) * 0.015;

    return ClipRect(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(rotationX)
          ..rotateY(rotationY)
          ..scale(scale),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _presets[_preset],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -100 + normalizedX * 100,
                top: -100 + normalizedY * 100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
              ),

              Positioned(
                right: -120 - normalizedX * 120,
                bottom: -100 - normalizedY * 100,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPresets() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Background',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(
                    _presets.length,
                    (index) {
                      final selected = _preset == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _preset = index;
                          });

                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 3,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _presets[index],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
