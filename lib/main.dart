import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

void main() => runApp(FlowerRecognitionApp());

class FlowerRecognitionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetalVision',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  Interpreter? _interpreter;
  String _prediction = "No image selected.";
  String? _currentFlower;
  String? _confidencePercentage;
  bool _isProcessing = false;
  final picker = ImagePicker();
  final int inputSize = 128;
  List<String> _labels = [];

  final Map<String, String> _flowerDescriptions = {
    'Daisy': 'Daisies are composite flowers from the Asteraceae family with white petals and a yellow center. They symbolize innocence and purity, and are found in temperate regions around the world.',
    'Dandelion': 'Dandelions are hardy flowering plants known for their bright yellow blossoms and puffball seed heads. They are used in traditional medicine and symbolize resilience and hope.',
    'Lavender': 'Lavender is a fragrant herb from the mint family, often used in aromatherapy and skincare. Its purple flowers symbolize calmness, grace, and serenity.',
    'Lilly': 'Lilies grow from bulbs and produce large, fragrant flowers with symbolic meanings of purity and motherhood. They are popular in gardens and floral arrangements.',
    'Lotus': 'The lotus is a sacred aquatic plant symbolizing purity and enlightenment in many cultures. It has large, floating leaves and blooms above the water surface.',
    'Orchid': 'Orchids are highly diverse flowers known for their symmetry and unique pollination strategies. They represent love, beauty, and strength.',
    'Rose': 'Roses are iconic flowering plants with layered petals and a strong fragrance. They are globally recognized symbols of love, passion, and romance.',
    'Sunflower': 'Sunflowers are tall plants with large yellow blooms that follow the sun. They symbolize loyalty and longevity and are valued for their seeds and oil.',
    'Tulip': 'Tulips are spring-blooming perennials known for their colorful, cup-shaped flowers. They symbolize perfect love and are historically tied to "Tulip Mania" in the Netherlands.',
  };

  final Map<String, String> _flowerImages = {
    'Daisy': 'assets/images/daisy.png',
    'Dandelion': 'assets/images/dandelion.png',
    'Lavender': 'assets/images/lavender.png',
    'Lilly': 'assets/images/lilly.png',
    'Lotus': 'assets/images/lotus.png',
    'Orchid': 'assets/images/orchid.png',
    'Rose': 'assets/images/rose.png',
    'Sunflower': 'assets/images/sunflower.png',
    'Tulip': 'assets/images/tulip.png',
  };

  @override
  void initState() {
    super.initState();
    loadModel();
    loadLabels();
  }

  Future<void> loadLabels() async {
    final rawLabels = await rootBundle.loadString('assets/labels.txt');
    setState(() {
      _labels = rawLabels.split('\n').map((e) => e.trim()).toList();
    });
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/flower_recognition_model.tflite');
      print('Model loaded');
    } catch (e) {
      print('Error loading model: $e');
      setState(() {
        _prediction = "Error loading model!";
      });
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _prediction = "Processing...";
        _isProcessing = true;
      });
      await runModelOnImage(File(pickedFile.path));
    }
  }

  Future<void> runModelOnImage(File imageFile) async {
    if (_interpreter == null) {
      setState(() {
        _prediction = "Model not loaded!";
        _isProcessing = false;
      });
      return;
    }

    var bytes = imageFile.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      setState(() {
        _prediction = "Failed to decode image.";
        _isProcessing = false;
      });
      return;
    }

    img.Image resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
    Float32List input = imageToFloat32List(resizedImage);

    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
    _interpreter!.run(input.reshape([1, inputSize, inputSize, 3]), output);

    double maxScore = 0;
    int maxIndex = 0;
    for (int i = 0; i < _labels.length; i++) {
      if (output[0][i] > maxScore) {
        maxScore = output[0][i];
        maxIndex = i;
      }
    }

    final label = _labels[maxIndex];
    final confidence = (maxScore * 100).toStringAsFixed(2);

    setState(() {
      _prediction = "$label ($confidence%)";
      _currentFlower = label;
      _confidencePercentage = confidence;
      _isProcessing = false;
    });
  }

  Float32List imageToFloat32List(img.Image image) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int index = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        int pixel = image.getPixel(x, y);
        buffer[index++] = img.getRed(pixel) / 255.0;
        buffer[index++] = img.getGreen(pixel) / 255.0;
        buffer[index++] = img.getBlue(pixel) / 255.0;
      }
    }
    return convertedBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.indigo,
              Colors.purple
            ],
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            'PetalVision',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            _image != null
                ? Image.file(_image!, height: 250)
                : Icon(Icons.image, size: 200, color: Colors.grey),
            SizedBox(height: 20),
            _isProcessing
                ? CircularProgressIndicator()
                : _currentFlower != null
                    ? Card(
                        margin: EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.grey[900],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (_flowerImages[_currentFlower!] != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    _flowerImages[_currentFlower!]!,
                                    height: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              SizedBox(height: 12),
                              Text(
                                _currentFlower!,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                "Confidence: $_confidencePercentage%",
                                style: TextStyle(fontSize: 16, color: Colors.greenAccent),
                              ),
                              SizedBox(height: 10),
                              Text(
                                _flowerDescriptions[_currentFlower!] ?? 'No description available.',
                                style: TextStyle(fontSize: 15, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Text(
                        _prediction,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text("Gallery"),
                ),
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera),
                  label: Text("Camera"),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
