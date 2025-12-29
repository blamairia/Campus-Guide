<div align="center">

# 🎓 Campus Guide

### Smart University Navigation App

[![Flutter](https://img.shields.io/badge/Flutter-3.27-02569B?logo=flutter)](https://flutter.dev)
[![Mapbox](https://img.shields.io/badge/Mapbox-Maps-000000?logo=mapbox)](https://www.mapbox.com/)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-ready Flutter navigation app for university campuses with real-time GPS tracking, turn-by-turn navigation, and voice guidance.

[Features](#-features) • [Screenshots](#-screenshots) • [Tech Stack](#-tech-stack) • [Installation](#-installation) • [Download](#-download)

</div>

---

## � Screenshots

<div align="center">

| Map View | Building List | Navigation |
|:--------:|:-------------:|:----------:|
| ![Map](docs/screenshots/map.png) | ![List](docs/screenshots/list.png) | ![Nav](docs/screenshots/nav.png) |

</div>

---

## ✨ Features

### 🗺️ Interactive Map
- Satellite imagery with Mapbox SDK
- Color-coded markers by building type
- Zoom-responsive marker scaling
- Real-time GPS location tracking

### 🧭 Turn-by-Turn Navigation
- Visual route line on map
- Voice-guided instructions (TTS)
- Multiple transport modes (walking, cycling, driving)
- Distance and ETA calculations

### 🏢 Building Directory
- Search and filter buildings
- Category-based filtering
- Distance badges with walking time
- Pull-to-refresh with haptic feedback

### 📍 Multi-Campus Support
- Sidi Amar Campus
- Bouni Campus  
- Sidi Achor Campus

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.27 / Dart 3.6 |
| **Maps** | Mapbox Maps Flutter SDK |
| **Routing** | Mapbox Directions API / OpenRouteService |
| **Location** | Geolocator |
| **Voice** | Flutter TTS |

---

## 📥 Download

[![Download APK](https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android)](https://github.com/blamairia/Campus-Guide/releases/latest)

---

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.27+
- Android Studio / VS Code
- Mapbox Access Token

### Setup

```bash
git clone https://github.com/blamairia/Campus-Guide.git
cd Campus-Guide

# Copy environment template
cp assets/config/.env.example assets/config/.env
cp android/gradle.properties.example android/gradle.properties

# Add your Mapbox tokens to both files

flutter pub get
flutter run
```

---

## 📂 Project Structure

```
lib/
├── constants/          # Theme, building data
├── screens/            # Map, list, navigation screens
├── services/           # Routing providers (Mapbox/ORS)
├── widgets/            # Reusable components
└── models/             # Data models
```

---

## 👤 Author

**Billel Lamairia**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/billel-lamairia-94141723b)
[![Email](https://img.shields.io/badge/Email-EA4335?logo=gmail&logoColor=white)](mailto:blamairia@gmail.com)

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">

Made for University Badji Mokhtar Annaba

</div>
