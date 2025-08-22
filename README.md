# flutter_ocr_app

A new Flutter project.

# Ingredient's Detection Using OCR

## Project Overview
This project is a Flutter-based mobile application that performs Optical Character Recognition (OCR) on food packaging to extract ingredient lists.
It then classifies the detected ingredients into dietary categories:
- Gluten-Free
- Vegan
- Vegetarian

The classification is rule-based, using keyword matching for lightweight, offline capability. No heavy machine learning models are required, making the app cross-platform and privacy-friendly.

---

## Features
- Camera capture: Take a picture of the food packaging directly from the app.
- Gallery import: Choose an existing image from the device gallery.
- OCR processing: Extract text using Google ML Kit's Text Recognition.
- Dietary classification: Classify ingredients as gluten-free, vegan, or vegetarian.
- Offline functionality: No internet connection required for OCR or classification.

---

## Technology Stack
- Flutter (Dart) – Cross-platform mobile app development
- Google ML Kit (Text Recognition) – OCR engine
- Rule-based classification – Lightweight and modular

---

## Project Structure
lib/
├── main.dart                    # App entry point with OCR & classification logic (clean)
├── filepickncamlogicmain.dart   # Fully commented/annotated version (documentation)
android/                         # Android-specific configuration
ios/                             # iOS-specific configuration
pubspec.yaml                     # Dependencies and assets

---

## Quick Start
git clone https://github.com/Championpapie/Msc_Project.git
cd Msc_Project
flutter pub get
flutter run

---

## Documentation Note
- lib/main.dart is the clean execution file used to build/run the app.
- lib/filepickncamlogicmain.dart is a documented version with inline explanations for clarity and assessment.
