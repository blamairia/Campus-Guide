# Campus Guide v2.0 🎓

A modern, high-performance Flutter application for university campus navigation. Features interactive maps, turn-by-turn navigation, and detailed building information.

## 🚀 Key Features

### 🗺️ Interactive Map
- **Satellite View:** High-resolution Mapbox satellite imagery.
- **Custom Markers:** Color-coded markers by building type (Dept, Amphi, Admin, etc.).
- **User Tracking:** Real-time GPS location tracking.

### 🧭 Navigation System
- **Turn-by-Turn Routing:** Visual route line on map.
- **Voice Instructions:** Text-to-Speech (TTS) guidance.
- **Arrival Detection:** Automatic notification when destination reached.
- **Instant Estimates:** Haversine formula for instant distance/time calculation (No API cost).

### 🏢 Building Directory
- **Smart Filters:** Filter by Department, Amphitheater, Library, Research, etc.
- **Search:** Real-time text search for buildings.
- **Campus Switching:** Instant switching between multiple campuses (Sidi Amar, Bouni, Sidi Achor).
- **Details:** Images, distance, and walking time estimates.

### ⚡ Performance Optimized
- **Compressed Assets:** Image sizes reduced by 99% (~7MB → ~60KB).
- **GPU Fixes:** Optimized for Samsung Exynos devices (Impeller disabled).
- **Texture Mode:** Enhanced map rendering stability.

---

## 📱 Tech Stack

- **Framework:** Flutter 3.27.1 / Dart 3.6.0
- **Language:** Kotlin 2.0.0 (Android)
- **Map SDK:** `mapbox_maps_flutter` v2.5.0
- **Navigation:** Mapbox Directions API
- **State Management:** `setState` (Clean & efficient for this scale)

---

## 🛠️ Setup & Installation

### Prerequisites
- Flutter SDK 3.27+
- Android Studio / VS Code
- Mapbox Access Token

### Environment Keys
Create a `.env` file in the root directory (or use `gradle.properties`):
```properties
MAPBOX_ACCESS_TOKEN=pk.eyJ1Ijoi...
MAPBOX_DOWNLOADS_TOKEN=sk.eyJ1Ijoi...
```

### Installation
```bash
# 1. Clone repository
git clone https://github.com/yourusername/campus-guide.git

# 2. Install dependencies
flutter pub get

# 3. Run on Android device
flutter run
```

---

## 📸 Screenshots

| Map View | Navigation | Building List |
|----------|------------|---------------|
| ![Map](assets/screenshots/map.jpg) | ![Nav](assets/screenshots/nav.jpg) | ![List](assets/screenshots/list.jpg) |

---

## 📝 License

© 2024 University Annaba. All Rights Reserved.
