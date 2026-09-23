import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
  File? _customImage;
  double _sensitivity = 1.0;
  bool _blurEnabled = true;
  bool _permissionGranted = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load saved image path
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('custom_image_path');
    
    if (imagePath != null && File(imagePath).existsSync()) {
      setState(() {
        _customImage = File(imagePath);
      });
    }
    
    setState(() {
      _permissionGranted = true;
    });
  }

  void _updateTilt(double x, double y) {
    setState(() {
      _tiltX = (x * _sensitivity).clamp(-30.0, 30.0);
      _tiltY = (y * _sensitivity).clamp(-30.0, 30.0);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Save image to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final savedImage = File('${appDir.path}/custom_background.jpg');
        await File(image.path).copy(savedImage.path);
        
        // Save path to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('custom_image_path', savedImage.path);
        
        setState(() {
          _customImage = savedImage;
        });
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _clearImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_image_path');
    setState(() {
      _customImage = null;
    });
    _showSnackBar('Background reset to default');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                final event = snapshot.data!;
                _updateTilt(event.x, event.y);
              }
              return Container();
            },
          ),
          
          // Background layer
          _buildTiltLayer(0),
          
          // Foreground gradient overlay
          _buildForegroundLayer(),
          
          // Settings button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 32),
              onPressed: _showSettings,
            ),
          ),
          
          // Permission prompt
          if (!_permissionGranted)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.screen_rotation,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Enable Motion Sensors',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _permissionGranted = true),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Grant Permission'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTiltLayer(int index) {
    final maxTilt = 30.0;
    final normalizedY = _tiltY / maxTilt;
    final normalizedX = _tiltX / maxTilt;
    final rotateY = normalizedY * 15.0;
    final rotateX = -normalizedX * 15.0;
    final scale = 1.05;
    final blur = _blurEnabled ? math.max(0, normalizedY.abs() * 5.0) : 0;

    Widget child;
    
    if (_customImage != null && index == 0) {
      child = Image.file(
        _customImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      child = Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
      );
    }

    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotateX * math.pi / 180.0)
            ..rotateY(rotateY * math.pi / 180.0)
            ..scale(scale),
          child: blur > 0
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: child,
                )
              : child,
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
    final scale = 1.03;
    final blur = _blurEnabled ? math.max(0, normalizedY.abs() * 8.0) : 0;

    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x66f093fb), Color(0x66f5576c)],
          ),
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(rotateX * math.pi / 180.0)
            ..rotateY(rotateY * math.pi / 180.0)
            ..scale(scale),
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

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Image upload
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose Custom Image'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Clear image
            if (_customImage != null)
              ElevatedButton.icon(
                onPressed: _clearImage,
                icon: const Icon(Icons.delete),
                label: const Text('Remove Custom Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            
            const SizedBox(height: 15),
            
            // Sensitivity
            const Text('Tilt Sensitivity'),
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
              title: const Text('Enable Blur Effect'),
              value: _blurEnabled,
              onChanged: (value) => setState(() => _blurEnabled = value),
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
