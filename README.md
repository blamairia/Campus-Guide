<div align="center">

# 🎓 Campus Guide

### Smart University Navigation App

[![Flutter](https://img.shields.io/badge/Flutter-3.27-02569B?logo=flutter)](https://flutter.dev)
[![Mapbox](https://img.shields.io/badge/Mapbox-Maps-000000?logo=mapbox)](https://www.mapbox.com/)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**A production-ready Flutter navigation app for university campuses with real-time GPS tracking, turn-by-turn navigation, and an elegant Google Maps-inspired UI.**

[Features](#-features) • [Demo](#-demo) • [Tech Stack](#-tech-stack) • [Installation](#-installation) • [Contact](#-contact)

</div>

---

## 📱 Demo

<!-- Add your demo video/gif here -->
<div align="center">

| Map View | Building List | Navigation |
|:--------:|:-------------:|:----------:|
| ![Map View](docs/screenshots/map_view.webp) | ![Building List](docs/screenshots/building_list.webp) | ![Navigation](docs/screenshots/navigation.webp) |

<!-- Uncomment when you have a demo video -->
<!-- 
### 🎬 Full Demo Video
![Campus Guide Demo](docs/demo/campus_guide_demo.webp)
-->

</div>

---

## ✨ Features

### 🗺️ Interactive Map
- **Satellite Imagery** — High-resolution Mapbox satellite view
- **Smart Markers** — Color-coded by building type, scale with zoom
- **Real-time Location** — Google Maps-style blue dot with pulsing effect
- **Accuracy Ring** — Visual GPS precision indicator

### 🧭 Turn-by-Turn Navigation
- **Visual Route Line** — Clear path displayed on map
- **Voice Guidance** — Text-to-Speech navigation instructions
- **Transport Modes** — Walking, cycling, and driving options
- **Bearing Indicator** — Direction cone showing heading
- **Arrival Detection** — Automatic notification on destination

### 🏢 Building Directory
- **Animated Filters** — Smooth horizontal scroll filter pills
- **Real-time Search** — Instant building search with clear button
- **Distance Badges** — Walking distance using Haversine formula
- **Staggered Animations** — 60fps fade-in list animations
- **Pull to Refresh** — Haptic feedback on refresh

### 📍 Multi-Campus Support
- **3 Campuses** — Sidi Amar, Bouni, Sidi Achor
- **Instant Switching** — Side drawer for campus selection
- **Persistent Data** — Each campus with unique buildings

### ⚡ Performance
- **99% Asset Compression** — ~7MB → ~60KB images
- **GPU Optimized** — Samsung Exynos compatibility
- **Shimmer Loading** — Skeleton placeholders for perceived speed

---

## �️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.27.1 / Dart 3.6.0 |
| **Maps** | Mapbox Maps Flutter SDK v2.5+ |
| **Navigation** | Mapbox Directions API |
| **Location** | Geolocator + Location Component |
| **Voice** | Flutter TTS |
| **State** | setState (clean for scale) |

---

## � Installation

### Prerequisites
- Flutter SDK 3.27+
- Android Studio / VS Code
- Mapbox Access Token ([Get one free](https://account.mapbox.com/))

### Setup

```bash
# Clone the repository
git clone https://github.com/blamairia/Campus-Guide.git
cd Campus-Guide

# Create environment file
echo "MAPBOX_ACCESS_TOKEN=pk.your_token_here" > assets/config/.env

# Install dependencies
flutter pub get

# Run on Android device
flutter run
```

### Mapbox Configuration

Add your Mapbox download token to `android/gradle.properties`:
```properties
MAPBOX_DOWNLOADS_TOKEN=sk.your_secret_token
```

---

## 📂 Project Structure

```
lib/
├── constants/
│   ├── app_theme.dart      # Design system (colors, typography, spacing)
│   └── buildings.dart      # Building data & types
├── screens/
│   ├── university_map.dart     # Map screen with markers
│   ├── university_table.dart   # Building list screen
│   ├── navigation_screen.dart  # Turn-by-turn navigation
│   └── home_management.dart    # Tab navigation & drawer
├── widgets/
│   └── carousel_card.dart  # Map carousel cards
├── helpers/
│   └── distance_utils.dart # Haversine formula
└── services/
    └── navigation_service.dart # GPS & routing
```

---

## 🎨 Design System

The app uses a clean, Google Maps-inspired light theme:

| Token | Value | Usage |
|-------|-------|-------|
| `primary` | `#2E7D32` | Campus green accent |
| `bgPrimary` | `#FAFAFA` | Page background |
| `bgSurface` | `#FFFFFF` | Cards & elevated surfaces |
| `textPrimary` | `#1A1A1A` | Headings |
| `textSecondary` | `#6B7280` | Body text |

---

## � Free Distribution Options

Since Google Play requires a $25 developer fee, here are **free alternatives**:

| Platform | Fee | Best For |
|----------|-----|----------|
| **[GitHub Releases](https://github.com/blamairia/Campus-Guide/releases)** | Free | Direct APK download |
| **[Amazon Appstore](https://developer.amazon.com/apps-and-games)** | Free | Wide Android reach |
| **[Samsung Galaxy Store](https://seller.samsungapps.com/)** | Free | Samsung devices |
| **[Huawei AppGallery](https://developer.huawei.com/consumer/)** | Free | Huawei/Honor devices |
| **[APKPure](https://apkpure.com/)** | Free | Open repository |
| **[F-Droid](https://f-droid.org/)** | Free | Open-source apps |

> 💡 **Recommendation**: Upload APK to GitHub Releases for immediate distribution, then submit to Amazon Appstore for broader reach.

---

## 📸 Screenshots

<details>
<summary><b>Click to expand all screenshots</b></summary>

### Splash Screen
![Splash](docs/screenshots/splash.webp)

### Map View with Markers
![Map](docs/screenshots/map_full.webp)

### Building List with Filters
![List](docs/screenshots/list_full.webp)

### Navigation Screen
![Navigation](docs/screenshots/navigation_full.webp)

### Campus Drawer
![Drawer](docs/screenshots/drawer.webp)

</details>

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## � Author

<div align="center">

**Billel Lamairia**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/billel-lamairia-94141723b)
[![Email](https://img.shields.io/badge/Email-EA4335?logo=gmail&logoColor=white)](mailto:blamairia@gmail.com)
[![Phone](https://img.shields.io/badge/Phone-25D366?logo=whatsapp&logoColor=white)](tel:+213668673666)

</div>

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**⭐ Star this repo if you found it helpful!**

Made with ❤️ for University Badji Mokhtar Annaba

</div>
