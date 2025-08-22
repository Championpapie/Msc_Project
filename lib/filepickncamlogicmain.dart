// Import required Dart & Flutter packages
import 'dart:io'; // For handling image files
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:camera/camera.dart'; // Camera access & control
import 'package:path_provider/path_provider.dart'; // Temporary directory paths
import 'package:path/path.dart' as p; // Path operations (e.g. join paths)
import 'package:image_picker/image_picker.dart'; // Pick images from gallery
import 'package:google_ml_kit/google_ml_kit.dart'; // ML Kit OCR library

// Function: Perform OCR on an image and return recognized text as String
Future<String> recognizeTextFromImage(File imageFile) async {
  final inputImage = InputImage.fromFile(imageFile); // Convert image file to ML Kit input format
  final textRecognizer = GoogleMlKit.vision.textRecognizer(); // Create a text recognizer instance
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage); // Run OCR
  await textRecognizer.close(); // Release resources
  return recognizedText.text; // Return the full extracted text
}

// Function: Classify OCR text into gluten-free, vegan, vegetarian
Map<String, bool> classifyText(String ocrText) {
  // Words that indicate gluten content
  final Set<String> glutenIngredients = {
    'wheat', 'barley', 'rye', 'spelt', 'malt', 'semolina', 'triticale'
  };

  // Non-vegan (animal products + meat)
  final Set<String> nonVeganIngredients = {
    'milk', 'cheese', 'butter', 'egg', 'honey', 'gelatin', 'whey',
    'casein', 'lactose', 'albumin', 'carmine',
    'chicken', 'beef', 'pork', 'lard', 'fish', 'anchovy', 'shrimp',
    'meat', 'bacon', 'ham'
  };

  // Non-vegetarian (meat/fish but excludes dairy/eggs)
  final Set<String> nonVegetarianIngredients = {
    'chicken', 'beef', 'pork', 'lard', 'fish', 'gelatin', 'anchovy', 'shrimp',
    'meat', 'bacon', 'ham'
  };

  // Convert all text to lowercase to make matching easier
  final text = ocrText.toLowerCase();

  // Check if text contains any restricted words
  bool hasGluten = glutenIngredients.any((item) => text.contains(item));
  bool hasNonVegan = nonVeganIngredients.any((item) => text.contains(item));
  bool hasNonVegetarian = nonVegetarianIngredients.any((item) => text.contains(item));

  // Return results as a map of booleans
  return {
    'gluten_free': !hasGluten,
    'vegan': !hasNonVegan,
    'vegetarian': !hasNonVegetarian,
  };
}

// Global list of device cameras (populated in main)
List<CameraDescription> cameras = [];

// Main entry point of the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for using plugins before runApp
  cameras = await availableCameras(); // Get all device cameras
  runApp(const MyApp()); // Launch the Flutter app
}

// Root widget of the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter OCR Camera App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), // Theme color
      ),
      home: const CameraScreen(), // Start at camera screen
    );
  }
}

// Main screen with camera preview, capture, gallery, and OCR output
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  // Camera controller
  late CameraController _controller;
  late Future<void> _initializeControllerFuture; // Camera init process
  bool _isCameraInitialized = false; // Flag for readiness

  // For captured or picked images
  XFile? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  // To display OCR raw text output
  String _ocrText = '';

  @override
  void initState() {
    super.initState();
    // Initialize camera with medium resolution
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize().then((_) {
      setState(() {
        _isCameraInitialized = true; // Mark as ready
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Release camera when screen closes
    super.dispose();
  }

  // Capture image using camera and classify text
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture; // Ensure camera ready
      final image = await _controller.takePicture(); // Capture image

      // Save captured image to temp storage
      final Directory tempDir = await getTemporaryDirectory();
      final String path = p.join(tempDir.path, '${DateTime.now()}.png');
      final File newImage = await File(image.path).copy(path);

      // Update UI with captured image
      setState(() {
        _capturedImage = XFile(newImage.path);
      });

      // Run OCR and classification
      final ocrText = await recognizeTextFromImage(File(newImage.path));
      final result = classifyText(ocrText);

      if (!mounted) return;
      setState(() {
        _ocrText = ocrText; // Save OCR text for display in UI
      });

      // Show classification results in a dialog
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

      // Snackbar to confirm saved path
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picture saved to: ${newImage.path}')),
      );
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  // Pick image from gallery and classify text
  Future<void> _pickImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
        });

        // OCR + classification
        final ocrText = await recognizeTextFromImage(File(pickedFile.path));
        final result = classifyText(ocrText);

        if (!mounted) return;
        setState(() {
          _ocrText = ocrText; // Save OCR text for display
        });

        // Show classification result dialog
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
          ? SingleChildScrollView( // Scrollable content to show OCR text fully
              child: Column(
                children: [
                  // Live camera preview
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                  const SizedBox(height: 20),

                  // Capture image button
                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera),
                    label: const Text("Capture"),
                  ),
                  const SizedBox(height: 10),

                  // Pick gallery image button
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Pick Image from Gallery"),
                  ),

                  // Show captured image
                  if (_capturedImage != null) ...[
                    const SizedBox(height: 20),
                    const Text("Captured Image:"),
                    Image.file(File(_capturedImage!.path), height: 200),
                  ],

                  // Show picked gallery image
                  if (_pickedImage != null) ...[
                    const SizedBox(height: 20),
                    const Text("Picked Image from Gallery:"),
                    Image.file(File(_pickedImage!.path), height: 200),
                  ],

                  // Expandable tile to show raw OCR text
                  if (_ocrText.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ExpansionTile(
                      title: const Text("View OCR Extracted Text"),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _ocrText,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
          : const Center(child: CircularProgressIndicator()), // Loader until camera is ready
    );
  }
}
