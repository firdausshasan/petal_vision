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
    'Lilly': 'Lilies are a group of flowering plants that grow from bulbs and are native to the temperate regions of the Northern Hemisphere. The genus Lilium comprises over 80 species, many of which are cultivated for their large, prominent, and fragrant flowers. Lilies are monocotyledons with six petal-like tepals and typically six stamens. Their reproductive biology and fragrant compounds attract various pollinators, including bees and butterflies. They are widely used in ornamental gardening and have symbolic meanings in various cultures, often representing purity, transience, and motherhood.',
    'Lotus': 'The lotus, commonly referred to as the sacred lotus, is a perennial aquatic plant belonging to the family Nelumbonaceae. Native to Asia, Nelumbo nucifera thrives in muddy, slow-moving freshwater habitats. The plant features large, circular leaves and striking pink to white flowers that bloom above the water surface. It is revered in religious and cultural contexts, particularly in Buddhism and Hinduism, symbolizing purity, enlightenment, and rebirth. Notably, the lotus exhibits thermoregulation (self-heating) and has seeds that can remain viable for hundreds of years, showcasing its extraordinary resilience.',
    'Orchid': 'Orchids are among the largest and most diverse families of flowering plants, with over 25,000 species and more than 100,000 hybrids. The family Orchidaceae is known for its complex flower morphology, specialized pollination mechanisms, and symbiotic relationships with mycorrhizal fungi. Orchid flowers typically have three sepals and three petals, one of which forms a distinctive lip (labellum) used to attract pollinators. Found in almost every habitat except glaciers, orchids vary from tiny epiphytic species to large terrestrial types. They symbolize love, beauty, strength, and luxury, and are extensively cultivated for horticultural and medicinal purposes.',
    'Sunflower': 'The sunflower is a large annual flowering plant native to North America, belonging to the Asteraceae family. Its name comes from its heliotropic behavior—the flower head turns to follow the sun throughout the day. Sunflowers can grow over 3 meters tall and have broad, rough leaves and large, yellow-rayed flower heads with hundreds of florets that mature into edible seeds. Rich in oil and nutrients, sunflower seeds are a major agricultural product. In addition to their economic value, sunflowers are also used in phytoremediation to extract toxins from the soil, making them an important plant in environmental science.',
    'Tulip': 'Tulips are spring-blooming bulbous perennials in the Liliaceae family, native to Central Asia and Turkey but widely cultivated worldwide. The genus Tulipa includes about 75 species and thousands of cultivars, prized for their cup-shaped, symmetrical flowers and wide range of vibrant colors. Tulips played a major role in economic history during the Dutch Golden Age in the 17th century, leading to the financial phenomenon known as "Tulip Mania." Tulips symbolize perfect love and rebirth and are known for their phototropic nature, often bending towards the light. Scientifically, tulips are studied for their chromosomal diversity and role in hybridization.',
  };

  final Map<String, String> _flowerImages = {
    'Lilly': 'assets/images/lilly.png',
    'Lotus': 'assets/images/lotus.png',
    'Orchid': 'assets/images/orchid.png',
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
    final rawLabels = await loadAssetLabels('assets/labels.txt');
    setState(() {
      _labels = rawLabels;
    });
  }

  Future<List<String>> loadAssetLabels(String assetPath) async {
    final labelsFile = await rootBundle.loadString(assetPath);
    return labelsFile.split('\n').map((e) => e.trim()).toList();
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

