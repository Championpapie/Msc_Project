import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

Future<String> recognizeTextFromImage(File imageFile) async {
  final inputImage = InputImage.fromFile(imageFile);
  final textRecognizer = GoogleMlKit.vision.textRecognizer();
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  await textRecognizer.close();
  return recognizedText.text;
}

Map<String, bool> classifyText(String ocrText) {
  final Set<String> glutenIngredients = {
    'wheat', 'barley', 'rye', 'spelt', 'malt', 'semolina', 'triticale'
  };

  final Set<String> nonVeganIngredients = {
    'milk', 'cheese', 'butter', 'egg', 'honey', 'gelatin', 'whey',
    'casein', 'lactose', 'albumin', 'carmine',
    // Extend with non-vegetarian items too since vegans avoid all
    'chicken', 'beef', 'pork', 'lard', 'fish', 'anchovy', 'shrimp',
    'meat', 'bacon', 'ham'
  };

  final Set<String> nonVegetarianIngredients = {
    'chicken', 'beef', 'pork', 'lard', 'fish', 'gelatin', 'anchovy', 'shrimp',
    'meat', 'bacon', 'ham'
  };

  final text = ocrText.toLowerCase();

  bool hasGluten = glutenIngredients.any((item) => text.contains(item));
  bool hasNonVegan = nonVeganIngredients.any((item) => text.contains(item));
  bool hasNonVegetarian = nonVegetarianIngredients.any((item) => text.contains(item));

  return {
    'gluten_free': !hasGluten,
    'vegan': !hasNonVegan,
    'vegetarian': !hasNonVegetarian,
  };
}

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter OCR Camera App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize().then((_) {
      setState(() {
        _isCameraInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      final Directory tempDir = await getTemporaryDirectory();
      final String path = p.join(tempDir.path, '${DateTime.now()}.png');
      final File newImage = await File(image.path).copy(path);

      setState(() {
        _capturedImage = XFile(newImage.path);
      });

      final ocrText = await recognizeTextFromImage(File(newImage.path));
      final result = classifyText(ocrText);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Classification Result"),
          content: Text(
            "Gluten-Free: ${result['gluten_free']! ? 'Yes' : 'No'}\n"
            "Vegan: ${result['vegan']! ? 'Yes' : 'No'}\n"
            "Vegetarian: ${result['vegetarian']! ? 'Yes' : 'No'}",
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picture saved to: ${newImage.path}')),
      );
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
        });

        final ocrText = await recognizeTextFromImage(File(pickedFile.path));
        final result = classifyText(ocrText);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Classification Result"),
            content: Text(
              "Gluten-Free: ${result['gluten_free']! ? 'Yes' : 'No'}\n"
              "Vegan: ${result['vegan']! ? 'Yes' : 'No'}\n"
              "Vegetarian: ${result['vegetarian']! ? 'Yes' : 'No'}",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Capture'),
      ),
      body: _isCameraInitialized
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: CameraPreview(_controller),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera),
                  label: const Text("Capture"),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Pick Image from Gallery"),
                ),
                if (_capturedImage != null) ...[
                  const SizedBox(height: 20),
                  const Text("Captured Image:"),
                  Image.file(File(_capturedImage!.path), height: 200),
                ],
                if (_pickedImage != null) ...[
                  const SizedBox(height: 20),
                  const Text("Picked Image from Gallery:"),
                  Image.file(File(_pickedImage!.path), height: 200),
                ],
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
