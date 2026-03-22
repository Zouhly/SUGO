<div align="center">

# SUGO

### **S**can & **U**pdate, **G**roceries **O**rganizer

A real-time grocery inventory app powered by Flutter & Firebase.  
Scan a barcode. Track your stock. Never run out again.

[![SonarCloud](https://sonarcloud.io/api/project_badges/measure?project=Zouhly_SUGO&metric=coverage)](https://sonarcloud.io/summary/new_code?id=Zouhly_SUGO)
[![SonarCloud](https://sonarcloud.io/api/project_badges/measure?project=Zouhly_SUGO&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=Zouhly_SUGO)
[![Flutter](https://img.shields.io/badge/Flutter-3.11-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase)](https://firebase.google.com)

</div>

---

## Features

### Barcode Scanning
- Instant barcode & QR code detection via the device camera
- **Existing product?** → Quantity auto-increments with a single scan
- **New product?** → A quick-add form slides up to register it on the spot
- 2-second cooldown prevents accidental duplicate scans

### Inventory Dashboard
- Live-updating product list — changes sync instantly via Firestore streams
- **Search** across name, barcode, or category
- **Category filter chips** generated dynamically from your inventory
- One-tap **+/−** buttons for quick stock adjustments
- **Edit** or **delete** any product with confirmation dialogs

### Stock Alerts
- Color-coded status badges: **OUT** (red) · **LOW** (orange)
- Summary bar showing total products, low-stock count, and out-of-stock count at a glance
- Configurable **minimum threshold** per product

### Scan History
- Every scan is logged with barcode, product name, action (`added` / `incremented`), and timestamp
- Recent activity stream (last 50 scans) for full audit trail

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.11 · Dart · Material 3 |
| **Database** | Cloud Firestore (real-time streams) |
| **Auth** | Firebase Auth |
| **Scanning** | mobile_scanner 7.2 |
| **Testing** | flutter_test · fake_cloud_firestore |
| **CI/CD** | GitHub Actions · SonarCloud |

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.11.3
- A Firebase project with Firestore enabled
- Physical device or emulator with camera access (for scanning)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/Zouhly/SUGO.git
cd SUGO

# 2. Install dependencies
flutter pub get

# 3. Add your Firebase config files (not tracked by git)
#    - android/app/google-services.json
#    - ios/Runner/GoogleService-Info.plist
#    - lib/firebase_options.dart

# 4. Run the app
flutter run
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## 📂 Project Structure

```
lib/
├── main.dart              # App entry point, navigation shell
├── models.dart            # Product & ScanLog data models
├── firestore_service.dart # Firestore CRUD operations (singleton)
├── inventory_page.dart    # Inventory dashboard UI
├── scanner_page.dart      # Barcode scanner UI
└── firebase_options.dart  # Firebase config (git-ignored)

test/
├── widget_test.dart            # App & navigation tests
├── models_test.dart            # Model serialization tests
├── firestore_service_test.dart # Service layer tests
├── inventory_page_test.dart    # Inventory UI tests
└── scanner_page_test.dart      # Scanner UI tests
```

---

## Security

This project follows a **Secure Software Development Lifecycle (SSDLC)** pipeline:

- **GitHub Actions** runs automated builds, tests, and coverage on every push and pull request.
- **SonarQube (SonarCloud)** performs static analysis, detecting code smells, vulnerabilities, and security hotspots.
- Firebase configuration files containing API keys are excluded from version control via `.gitignore` and injected as encrypted secrets during CI.

---


