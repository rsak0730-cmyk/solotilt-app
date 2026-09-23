import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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
  double _tiltX = 0;
  double _tiltY = 0;
  int _selectedPreset = 0;
  double _sensitivity = 1.0;
  bool _blurEnabled = true;

  // Pre-bundled gradient presets (no image picker needed!)
  final List<List<Color>> _presets = [
    [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
    [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Pink
    [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue
    [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green
    [const Color(0xFFfa709a), const Color(0xFFfee140)], // Sunset
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<GyroscopeEvent>(
            stream: gyroscopeEventStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                setState(() {
                  _tiltX = (snapshot.data!.x * _sensitivity).clamp(-30.0, 30.0);
                  _tiltY = (snapshot.data!.y * _sensitivity).clamp(-30.0, 30.0);
                });
              }
              return Container();
            },
          ),
          
          _buildBackgroundLayer(),
          _buildForegroundLayer(),
          
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.palette, color: Colors.white, size: 32),
              onPressed: _showPresets,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundLayer() {
    final maxTilt = 30.0;
    final normalizedY = _tiltY / maxTilt;
    final normalizedX = _tiltX / maxTilt;
    final rotateY = normalizedY * 15.0;
    final rotateX = -normalizedX * 15.0;
    final blur = _blurEnabled ? math.max(0, normalizedY.abs() * 5.0) : 0;

    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _presets[_selectedPreset],
          ),
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotateX * math.pi / 180.0)
            ..rotateY(rotateY * math.pi / 180.0)
            ..scale(1.05),
          child: blur > 0
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(),
                )
              : Container(),
        ),
      ),
    );
  }

  Widget _buildForegroundLayer() {
    final maxTilt = 30.0;
    final normalizedY = _tiltY / maxTilt;
    final normalizedX = _tiltX / maxTilt;
    final rotateY = normalizedY * 20.0;
    final rotateX = -normalizedX * 20.0;
    final blur = _blurEnabled ? math.max(0, normalizedY.abs() * 8.0) : 0;

    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _presets[_selectedPreset][0].withOpacity(0.6),
              _presets[_selectedPreset][1].withOpacity(0.6),
            ],
          ),
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotateX * math.pi / 180.0)
            ..rotateY(rotateY * math.pi / 180.0)
            ..scale(1.03),
          child: blur > 0
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(),
                )
              : Container(),
        ),
      ),
    );
  }

  void _showPresets() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Background',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: List.generate(
                _presets.length,
                (index) => GestureDetector(
                  onTap: () {
                    setState(() => _selectedPreset = index);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedPreset == index ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _presets[index],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Sensitivity slider
            const Text('Sensitivity'),
            Slider(
              value: _sensitivity,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _sensitivity.toStringAsFixed(1),
              onChanged: (value) => setState(() => _sensitivity = value),
            ),
            
            // Blur toggle
            SwitchListTile(
              title: const Text('Enable Blur'),
              value: _blurEnabled,
              onChanged: (value) => setState(() => _blurEnabled = value),
            ),
          ],
        ),
      ),
    );
  }
}
