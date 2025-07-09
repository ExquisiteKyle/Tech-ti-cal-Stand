# Techtical Stand - Tower Defense Game

A modern, engaging tower defense game built with Flutter, demonstrating advanced frontend development skills with beautiful UI/UX design and complex game mechanics.

## 🎮 Game Overview

Techtical Stand is a strategic tower defense game where players build and upgrade towers to defend against waves of enemies. Built with Flutter and Dart, this project showcases modern game development techniques, responsive design, and robust state management.

### Key Features

- **Strategic Gameplay**: Multiple tower types with unique abilities and upgrade paths
- **Beautiful Visuals**: Smooth 60fps animations, particle effects, and modern UI design
- **Progressive Difficulty**: Multiple levels with increasing challenge and unique enemy paths
- **Cross-platform**: Native performance on mobile, web, and desktop
- **Accessibility**: Color blind support, adjustable text scaling, and haptic feedback

## 🏗️ Architecture & Technical Stack

### Core Technologies

- **Flutter 3.x** - UI framework for cross-platform development
- **Dart 3.x** - Programming language
- **Riverpod** - State management and dependency injection
- **Custom Game Engine** - Built-in game loop, physics, and rendering system

### Project Structure

```
lib/
├── core/                    # Core utilities and game engine
│   ├── audio/              # Audio management system
│   ├── game/               # Game loop and entity management
│   ├── rendering/          # Canvas rendering and game painter
│   ├── theme/              # Accessibility and color management
│   └── widgets/            # Reusable UI components
├── features/               # Feature-based modules
│   └── game/               # Game-specific features
│       ├── domain/         # Game models and business logic
│       └── presentation/   # UI screens and providers
└── shared/                 # Shared components and utilities
```

## 🎯 Core Gameplay Mechanics

### Tower System

- **4 Unique Tower Types**: Archer, Cannon, Magic, and Sniper towers
- **Strategic Placement**: Drag-and-drop tower placement with tile-based system
- **Upgrade System**: Visual upgrade paths with cost management
- **Special Abilities**: Each tower type has unique attack patterns and effects

### Enemy System

- **Multiple Enemy Types**: Goblin, Orc, Troll, and Boss enemies
- **Wave Progression**: Increasingly difficult waves with different enemy combinations
- **Pathfinding**: Enemies follow predetermined paths with waypoint navigation
- **Health & Armor**: Different enemy types have varying health and resistance

### Game Mechanics

- **Resource Management**: Gold economy for tower placement and upgrades
- **Wave System**: Progressive difficulty with strategic timing
- **Collision Detection**: Precise hit detection for projectiles and enemies
- **Performance Optimization**: Efficient rendering and entity management

**Gameplay Demo** - Defense

<img src="assets/images/battle-demo-xs.gif" width="200" alt="Gameplay Demo">

## 🎨 UI/UX Design

### Visual Design Principles

- **Modern Aesthetic**: Clean, colorful design with consistent theming
- **Responsive Layout**: Adapts to different screen sizes and orientations
- **Visual Feedback**: Immediate response to user interactions
- **Accessibility**: High contrast colors, readable text, and touch-friendly targets

### User Experience

- **Intuitive Controls**: Easy-to-learn drag-and-drop mechanics
- **Progressive Disclosure**: Information revealed as needed
- **Smooth Animations**: 60fps gameplay with fluid transitions
- **Audio Integration**: Immersive sound effects and music system

## 🧪 Testing & Quality Assurance

### Comprehensive Test Suite

- **Unit Tests**: Game logic, tower behavior, and utility functions
- **Widget Tests**: UI component behavior and user interactions
- **Integration Tests**: Complete game flow and level progression
- **Performance Tests**: Frame rate and memory usage validation

### Code Quality

- **Static Analysis**: Dart analyzer with custom rules
- **Code Formatting**: Consistent style with dart format
- **Documentation**: Comprehensive API documentation
- **Error Handling**: Robust error management and logging

## 🚀 Performance Optimization

### Technical Achievements

- **60 FPS Gameplay**: Consistent frame rate across all platforms
- **Memory Management**: Efficient object pooling and garbage collection
- **Rendering Optimization**: Only render visible elements
- **Asset Optimization**: Compressed textures and audio files

### Platform Support

- **Mobile**: Optimized for Android and iOS with touch controls
- **Web**: Responsive design with keyboard and mouse support
- **Desktop**: Native performance on Windows, macOS, and Linux

## 🛠️ Development Setup

### Prerequisites

- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android Studio or VS Code with Flutter extensions
- Git for version control

### Quick Start

```bash
# Clone the repository
git clone https://github.com/ExquisiteKyle/Tech-ti-cal-Stand.git
cd Tech-ti-cal-Stand

# Install dependencies
flutter pub get

# Run the game
flutter run

# Run tests
flutter test

# Build for production
flutter build apk --release  # Android
flutter build web           # Web
```

## 📱 Game Features

### Currently Implemented

- ✅ Complete tower defense gameplay loop
- ✅ 4 unique tower types with distinct abilities
- ✅ Multiple enemy types with different behaviors
- ✅ 3 levels with unique path designs
- ✅ Drag-and-drop tower placement system
- ✅ Resource management and economy
- ✅ Wave-based enemy spawning
- ✅ Collision detection and projectile system
- ✅ Audio system with sound effects and music
- ✅ Accessibility features (color blind support, text scaling)
- ✅ Settings system with customizable options
- ✅ Level selection and progression
- ✅ Responsive UI design
- ✅ Cross-platform compatibility

**Main Menu Features** - Level selection, settings, and achievements

<img src="assets/images/menu-demo-xs.gif" width="200" alt="Main Menu Demo">

### Technical Highlights

- **Custom Game Engine**: Built from scratch using Flutter's Canvas API
- **State Management**: Robust Riverpod-based state management
- **Performance**: Optimized for 60fps gameplay on all platforms
- **Architecture**: Clean, maintainable code with feature-based organization
- **Testing**: Comprehensive test coverage for all core systems

### Project Status

- **Current Version**: MVP (Minimum Viable Product) - Core gameplay complete
- **Focus**: Technical foundation, performance optimization, and cross-platform compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

**Built with ❤️ using Flutter and Dart**
