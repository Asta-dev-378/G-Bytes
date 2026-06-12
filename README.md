<div align="center">

# 🧠 G-Bytes

**Unlock Your Brain's Full Potential with Gamified Cognitive Training**

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" /></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-333333?style=for-the-badge&logo=android&logoColor=white" alt="Platform" /></a>
</p>

<p align="center">
  <a href="#-overview">Overview</a> •
  <a href="#-features">Features</a> •
  <a href="#-screenshots--demo">Screenshots</a> •
  <a href="#-getting-started">Getting Started</a>
</p>

</div>

---

## 📋 Overview

**G-Bytes** is a comprehensive brain training and wellness application designed to help you enhance focus, memory, and mental agility. By blending **scientifically-inspired cognitive games**, **productivity timers**, and an **integrated music player**, G-Bytes creates an engaging ecosystem for mental improvement. 

Built with Flutter and meticulously crafted with Material 3 design principles, G-Bytes guarantees a smooth, beautiful, and highly responsive user experience across devices.

---

## ✨ Key Highlights

- 🧠 **5 Unique Brain Games** - Master Memory, Logic, Math Sprint, Schulte Table, and Stroop Effect.
- ⏱️ **Advanced Timer Suite** - Stay productive with Classic countdowns or push yourself with customizable HIIT interval training.
- 🎵 **Integrated Music Player** - Listen to curated focus tracks or import your custom audio—complete with background playback.
- 🏆 **21-Tier League System** - Rank up, earn points, and track your daily streaks.
- 🎨 **Dynamic Theming & Personalization** - Choose between vibrant color schemes (Orange, Cyan, Purple) and custom timer animations.
- 📊 **In-depth Analytics** - Monitor high scores, track session stats, and visualize your cognitive growth.

---

## 📸 Screenshots & Demo

> 💡 **Tip:** To make this section look best, capture screenshots directly from your device or emulator and replace the placeholder images. A GIF showing gameplay is highly recommended!

### Interactive App Demo
<div align="center">
  <img src="https://placehold.co/800x400/1e1e1e/FFFFFF/png?text=App+Walkthrough+GIF+Here\n(Drag+and+drop+your+GIF+here)" alt="Demo GIF" width="800" style="border-radius: 12px;"/>
</div>

<br/>

### App Interface
<table align="center" style="border: none;">
  <tr>
    <td align="center" width="25%"><b>🏠 G-Zone (Dashboard)</b></td>
    <td align="center" width="25%"><b>🧠 Memory Game</b></td>
    <td align="center" width="25%"><b>⏱️ HIIT Timer</b></td>
    <td align="center" width="25%"><b>🎵 Music Player</b></td>
  </tr>
  <tr>
    <td align="center"><img src="https://placehold.co/300x600/1e1e1e/FFFFFF/png?text=G-Zone" width="200" style="border-radius: 8px;"/></td>
    <td align="center"><img src="https://placehold.co/300x600/1e1e1e/FFFFFF/png?text=Memory+Game" width="200" style="border-radius: 8px;"/></td>
    <td align="center"><img src="https://placehold.co/300x600/1e1e1e/FFFFFF/png?text=Timer+Screen" width="200" style="border-radius: 8px;"/></td>
    <td align="center"><img src="https://placehold.co/300x600/1e1e1e/FFFFFF/png?text=Music+Screen" width="200" style="border-radius: 8px;"/></td>
  </tr>
</table>

---

## 🎮 Features Breakdown

### 🧩 Brain Training Games

| Game | Description | Key Mechanics |
|------|-------------|---------------|
| **Memory Game** | Train your memory with pattern recognition | Dynamic grids (3×3 to 5×5), scalable difficulty |
| **Logic Game** | Enhance logical thinking with sequences | Multiple-choice sequence completion |
| **Math Sprint** | Rapid mental arithmetic in 60 seconds | Addition, multiplication, division with streak bonuses |
| **Schulte Table** | Speed test for visual attention | Scalable grids, hard mode, rapid number spotting |
| **Stroop Effect** | Test color-word cognitive interference | Match displayed meanings to ink colors, reaction tracking |

### ⏱️ Timer Suite

- **Classic Timer**: Perfect for Pomodoro or deep work. Supports 5, 10, 25, 45 minute presets or custom durations. Features ambient animations (jellyfish, bubble burst, stardust).
- **Interval Timer (HIIT)**: Tailor your workout or study intervals. Configure work duration (5-300s), rest duration (0-300s), and round counts (1-20). Audio cues included.

### 🎵 Audio Experience

- **Curated Library**: 10 pre-loaded ambient tracks designed specifically for focus and relaxation.
- **Custom Imports**: Import and play any audio file from your device.
- **Background Support**: Persistent audio playback even when the app is minimized.
- **System Controls**: Control playback directly from your device's notification shade.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.0 or higher)
- Dart SDK (v3.0 or higher)
- Android Studio / Xcode

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Asta-dev-378/G-Bytes.git
   cd G-Bytes
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

### Building for Production

<details>
<summary><b>View Build Commands</b></summary>

**Android (APK)**
```bash
flutter build apk --release
```

**Android (Google Play App Bundle)**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```
</details>

---

## 🏗️ Project Architecture

<details>
<summary><b>Explore the Directory Structure</b></summary>
<br>

```text
G-Bytes/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/                            # Data models (League, Stats)
│   ├── providers/                         # State management (Provider pattern)
│   │   ├── game_provider.dart             
│   │   ├── timer_provider.dart            
│   │   └── settings_provider.dart         
│   ├── screens/                           # UI Views
│   │   ├── home/                          # Dashboard & Hub
│   │   ├── timer/                         # Productivity UI
│   │   └── music/                         # Audio UI
│   └── services/                          # Background & Audio Services
├── assets/
│   ├── audio/                             # Original music files
│   ├── image/                             # UI graphics
│   └── fonts/                             # Custom typography
└── pubspec.yaml                           # Dependency configuration
```
</details>

### 🛠️ Tech Stack & Dependencies

- **Framework:** `Flutter`, `Dart`
- **State Management:** `provider`
- **Routing:** `go_router`
- **Audio Integration:** `just_audio`, `audio_service`, `audio_session`
- **Storage:** `shared_preferences`, `sqflite`
- **Animations:** `flutter_animate`

---

<div align="center">
  <b>Designed & Built by <a href="https://github.com/Asta-dev-378">Asta-dev-378</a></b>
  <br><br>
  <i>⭐ If G-Bytes helped you train your brain, consider giving this repo a star! ⭐</i>
</div>
