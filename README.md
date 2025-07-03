<p align="center">
  <img src="https://raw.githubusercontent.com/firdausshasan/petal_vision/refs/heads/main/assets/logo/petalvision.png" width="550" alt="PetalVision Icon">
</p>

# 🌸 PetalVision

<div align="justify">

PetalVision is a Flutter mobile application that utilizes a custom-built TensorFlow Lite (TFLite) model to identify different types of flowers from user-supplied images. Leveraging the power of machine learning, the app can accurately classify nine common flower species, including Daisy, Dandelion, Lavender, Lily, Lotus, Orchid, Rose, Sunflower, and Tulip. With a simple and intuitive interface, users can either capture a flower photo using their device’s camera or select an existing image from the gallery. Once processed, the app displays the flower name along with a high-resolution preview, making it a visually engaging experience. Petal Vision is not only a useful tool for plant enthusiasts and hobbyists but also serves as an educational platform for young learners. Its design makes it especially suitable for children who are beginning to explore nature and the diversity of plant life. By transforming flower identification into an interactive and visually stimulating activity, the app encourages curiosity and provides a fun introduction to botany. Whether used at home, in schools, or during outdoor exploration, Petal Vision helps foster environmental awareness and a love for learning about the natural world.

</div>



## 📱 Features

- 🌼 Real-time flower recognition using the device camera
- 🧠 Custom TFLite model trained on 9 flower classes:
  - Daisy
  - Dandelion
  - Lavender
  - Lily
  - Lotus
  - Orchid
  - Rose
  - Sunflower
  - Tulip
- 📷 Image capture and gallery upload options
- ⚡ Fast, on-device inference (no internet needed)
- 📊 Confidence score displayed for each prediction
- 🧩 Easy-to-use interface with clean UI

## 🚀 Getting Started

### 🔧 Prerequisites

- Flutter SDK (Latest stable)
- Android Studio or Visual Studio Code
- An emulator or physical Android device
- TFLite model and labels file

### 📥 Installation Steps

1. **Clone the Repository**
    ```bash
    git clone https://github.com/firdausshasan/petal_vision.git
    cd petal_vision
    ```

2. **Install Dependencies**
    ```bash
    flutter pub get
    ```

3. **Add Model Files**
    Put the following files inside the `assets/` directory:
    - `flower_recognition_model.tflite`
    - `labels.txt`

4. **Update `pubspec.yaml`**
    ```yaml
    flutter:
      assets:
        - assets/flower_recognition_model.tflite
        - assets/labels.txt
    ```

5. **Run the App**
    ```bash
    flutter run
    ```
---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.4
  tflite_flutter: ^0.11.0
  image: ^3.3.0
  ```

## 📱 How to Use PetalVision

### 1️⃣ Open the PetalVision App

<p align="center">
  <img src="https://raw.githubusercontent.com/firdausshasan/petal_vision/refs/heads/main/assets/steps/step%201.png" width="550" alt="Open App">
</p>

---

### 2️⃣ Tap on "Gallery" to Choose a Flower Image from Your Phone

<p align="center">
  <img src="https://raw.githubusercontent.com/firdausshasan/petal_vision/refs/heads/main/assets/steps/step%202.png" width="550" alt="Select from Gallery">
</p>

---

### 3️⃣ The App Will Detect the Flower and Show Its Name

<p align="center">
  <img src="https://raw.githubusercontent.com/firdausshasan/petal_vision/refs/heads/main/assets/steps/step%203.png" width="550" alt="Prediction Result">
</p>

---

### 📝 Tip:
You can also tap **"Camera"** instead of "Gallery" to take a photo of a flower in real-time.

## 👤 Target Users

- Children learning about flowers 🌼
- Teachers integrating botany into class 🌱
- Gardening hobbyists 🌿
- Nature lovers on the go 🌸






