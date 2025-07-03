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
    'Daisy': 'The daisy, belonging to the family Asteraceae, is a herbaceous flowering plant that exhibits a classic inflorescence known as a capitulum, where numerous small florets are arranged on a central disk, giving the appearance of a single flower. The most common species, Bellis perennis, is native to Europe but has become naturalized in many temperate regions around the world. Daisies are perennials and thrive in well-drained soils with full sun exposure. Their morphological structure consists of white ray florets surrounding yellow disk florets, which are involved in the plant’s reproductive cycle through both insect pollination and self-fertilization. Due to their hardy nature and photoperiodic flowering behavior, daisies play a role in ecological biodiversity and are often used in studies on plant development and stress resistance.',
    'Dandelion': 'Dandelions (Taraxacum officinale) are highly adaptive flowering plants in the Asteraceae family, known for their bright yellow composite flower heads and distinctive seed dispersal mechanism involving pappus-topped achenes. Native to Eurasia, they have colonized nearly every continent due to their effective reproductive strategies, including apomixis, where seeds form without fertilization. Dandelions exhibit a rosette of deeply lobed leaves and a hollow scape that supports the inflorescence. After pollination, the flower matures into a spherical seed head, facilitating wind-assisted seed dispersal. In addition to their ecological value, dandelions have long been used in traditional medicine for their diuretic and hepatoprotective properties, and they are being researched for bioactive compounds such as sesquiterpene lactones.',
    'Lavender': 'Lavender (Lavandula angustifolia), a perennial shrub in the Lamiaceae family, is renowned for its fragrant spikes of purple-blue flowers and essential oil production. Native to the Mediterranean region, lavender thrives in dry, well-drained soils with high sunlight exposure. The plant exhibits square stems and opposite leaves typical of the mint family. Its flowers are rich in volatile compounds like linalool and linalyl acetate, which possess antimicrobial, anxiolytic, and anti-inflammatory properties. The inflorescences attract pollinators, contributing to biodiversity, and the plant\'s drought resistance makes it valuable in xeriscaping. Lavender has commercial uses in perfumery, aromatherapy, and herbal medicine, and it is increasingly studied for its allelopathic effects on neighboring vegetation.',
    'Lilly': 'Lilies, classified under the genus Lilium in the family Liliaceae, are monocotyledonous flowering plants grown from scaly bulbs. Native to temperate regions of the Northern Hemisphere, they display large, showy flowers with six petal-like tepals, often marked with spots or streaks and borne on erect stems. Lilies reproduce through sexual pollination and vegetative bulb division. Their morphological diversity spans trumpet, bowl, and reflexed forms, and they are characterized by a superior ovary and trimerous floral symmetry. Lilies are significant in horticulture and floriculture due to their aesthetic appeal and symbolic meanings in various cultures. However, certain species contain alkaloids like colchicine, which are toxic to pets and are studied for their potential anti-mitotic properties in medical research.',
    'Lotus': 'The lotus (Nelumbo nucifera), often referred to as the sacred lotus, is a perennial aquatic plant native to Asia and classified in the family Nelumbonaceae. Unlike water lilies, lotus plants exhibit emergent leaves and flowers that rise above the water surface due to their thermogenic capability—an adaptation allowing them to attract pollinators by maintaining floral temperatures. The plant’s large, peltate leaves are hydrophobic due to micro- and nano-scale structures, a phenomenon known as the "lotus effect" which has inspired biomimetic self-cleaning surfaces. The lotus exhibits protogynous flowering, with female reproductive organs maturing before male organs to encourage cross-pollination. Rich in cultural, medicinal, and nutritional value, the plant’s seeds can remain viable for centuries due to their hardened seed coats and antioxidant content.',
    'Orchid': 'Orchids, members of the Orchidaceae family, represent one of the most diverse and evolutionarily advanced groups of flowering plants, with over 25,000 species. They exhibit complex floral structures adapted for specialized pollination mechanisms, including bilateral symmetry (zygomorphy), a unique reproductive column (gynostemium), and a highly modified petal known as the labellum. Many orchids engage in obligate symbiosis with mycorrhizal fungi, which aid seed germination and nutrient acquisition. Orchid pollination often involves deception, with flowers mimicking the appearance or scent of female insects to attract pollinators. Their ecological and horticultural significance is vast, and species such as Phalaenopsis and Cattleya are extensively cultivated for ornamental purposes and studied for floral morphogenesis and adaptive radiation.',
    'Rose': 'Roses, classified in the genus Rosa within the family Rosaceae, are perennial shrubs known for their compound leaves, thorny stems, and intricately layered flowers. With over 300 species and thousands of cultivars, roses exhibit a wide variety of forms and colors, often used to convey cultural symbolism. Their reproductive structure consists of numerous stamens and a hypanthium, with flowers ranging from single-petaled wild types to highly doubled modern hybrids. Roses are pollinated by insects and often undergo hybridization, contributing to their vast genetic diversity. Rich in phenolic compounds such as flavonoids and anthocyanins, roses are not only ornamental but also have therapeutic applications in skincare, perfumery, and traditional medicine.',
    'Sunflower': 'The sunflower (Helianthus annuus) is an annual dicotyledonous plant in the Asteraceae family, valued for its heliotropic behavior and agricultural significance. Native to North America, it features a large composite inflorescence composed of sterile ray florets and fertile disk florets arranged in a Fibonacci spiral, optimizing space and reproductive efficiency. Sunflowers exhibit phototropism during early growth stages and rely on insect pollination for seed production. Their seeds are rich in unsaturated fatty acids, particularly linoleic acid, and the plant is also cultivated for its phytoremediation capabilities, being able to absorb heavy metals from soil. The sunflower is a model organism in studies on circadian rhythm, gene expression, and plant-microbe interactions.',
    'Tulip': 'Tulips (Tulipa spp.), part of the Liliaceae family, are bulbous perennials native to Central Asia and widely naturalized across Europe. Their linear leaves and erect, cup-shaped flowers emerge in early spring, making them important ornamental crops. Tulip flowers are composed of six tepals and display a wide range of pigmentation due to anthocyanin and carotenoid synthesis. Historically, tulips played a central role in economic history during the Dutch "Tulip Mania" of the 17th century. Tulips exhibit geotropic and phototropic growth patterns and require vernalization—exposure to cold—to initiate blooming. In plant science, they are used as subjects to study floral induction, hormone regulation, and bulb dormancy.',
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