# Game Design Document - Techtical Stand

## Game Overview

**Techtical Stand** is a strategic tower defense game where players defend their base against waves of enemies by strategically placing and upgrading towers. The game emphasizes tactical thinking, resource management, and progressive difficulty.

## Core Gameplay Loop

### **Primary Loop**

1. **Wave Preparation**: Player analyzes upcoming enemy wave
2. **Tower Placement**: Strategic placement of towers along enemy path
3. **Resource Management**: Balance gold between new towers and upgrades
4. **Wave Defense**: Watch towers attack enemies and manage resources
5. **Wave Completion**: Earn gold and prepare for next wave
6. **Progression**: Unlock new towers, upgrades, and levels

### **Secondary Loops**

- **Tower Upgrades**: Improve existing towers for better performance
- **Achievement System**: Complete challenges for rewards
- **Level Progression**: Unlock new maps and challenges

## Game Systems

### **Tower System**

#### Archer Tower

- **Base Cost**: 50 gold
- **Damage**: 15
- **Range**: 120 pixels
- **Attack Speed**: 1.2 attacks/second
- **Target Priority**: First enemy in range
- **Special**: Fast attack speed, good against light enemies

**Upgrade Path 1 - Multi-shot**

- Level 1: 2 arrows per shot (100 gold)
- Level 2: 3 arrows per shot (200 gold)
- Level 3: 4 arrows per shot (400 gold)

**Upgrade Path 2 - Poison Arrows**

- Level 1: Poison damage over time (150 gold)
- Level 2: Increased poison duration (300 gold)
- Level 3: Poison spreads to nearby enemies (600 gold)

#### Cannon Tower

- **Base Cost**: 100 gold
- **Damage**: 40
- **Range**: 100 pixels
- **Attack Speed**: 0.8 attacks/second
- **Target Priority**: Closest enemy in range
- **Special**: Splash damage, effective against groups

**Upgrade Path 1 - Explosive Rounds**

- Level 1: 25% splash damage (150 gold)
- Level 2: 50% splash damage (300 gold)
- Level 3: 75% splash damage (600 gold)

**Upgrade Path 2 - Area Damage**

- Level 1: Increased splash radius (200 gold)
- Level 2: Stun effect on splash (400 gold)
- Level 3: Chain explosions (800 gold)

#### Magic Tower

- **Base Cost**: 150 gold
- **Damage**: 25
- **Range**: 140 pixels
- **Attack Speed**: 1.0 attacks/second
- **Target Priority**: Strongest enemy in range
- **Special**: Slows enemies, magical damage

**Upgrade Path 1 - Chain Lightning**

- Level 1: Lightning jumps to 2 enemies (200 gold)
- Level 2: Lightning jumps to 3 enemies (400 gold)
- Level 3: Lightning jumps to 4 enemies (800 gold)

**Upgrade Path 2 - Freeze Effect**

- Level 1: 20% slow effect (250 gold)
- Level 2: 40% slow effect (500 gold)
- Level 3: 60% slow effect + freeze chance (1000 gold)

#### Sniper Tower

- **Base Cost**: 200 gold
- **Damage**: 80
- **Range**: 200 pixels
- **Attack Speed**: 0.5 attacks/second
- **Target Priority**: Furthest enemy in range
- **Special**: Very high damage, long range

**Upgrade Path 1 - Critical Hits**

- Level 1: 15% critical hit chance (300 gold)
- Level 2: 30% critical hit chance (600 gold)
- Level 3: 50% critical hit chance (1200 gold)

**Upgrade Path 2 - Armor Piercing**

- Level 1: Ignores 25% armor (350 gold)
- Level 2: Ignores 50% armor (700 gold)
- Level 3: Ignores 75% armor (1400 gold)

### **Enemy System**

#### Goblin

- **Health**: 50
- **Speed**: 80 pixels/second
- **Gold Reward**: 10
- **Armor**: 0
- **Special**: Fast movement, low health
- **Weakness**: Archer towers

#### Orc

- **Health**: 150
- **Speed**: 60 pixels/second
- **Gold Reward**: 25
- **Armor**: 10
- **Special**: Balanced stats
- **Weakness**: Cannon towers

#### Troll

- **Health**: 300
- **Speed**: 40 pixels/second
- **Gold Reward**: 50
- **Armor**: 25
- **Special**: High health, slow movement
- **Weakness**: Magic towers

#### Boss

- **Health**: 1000
- **Speed**: 30 pixels/second
- **Gold Reward**: 200
- **Armor**: 50
- **Special**: Massive health, special abilities
- **Weakness**: Requires strategic tower combinations

### **Wave System**

#### **Wave Structure**

- **Wave 1-5**: Basic enemies (Goblins, Orcs)
- **Wave 6-10**: Introduction of Trolls
- **Wave 11-15**: Mixed enemy types, increased difficulty
- **Wave 16-20**: Boss waves, maximum challenge

#### **Wave Generation**

```dart
class WaveGenerator {
  static List<Enemy> generateWave(int waveNumber) {
    List<Enemy> enemies = [];

    // Base enemies per wave
    int baseEnemies = 5 + (waveNumber * 2);

    // Enemy type distribution
    double goblinChance = max(0.1, 0.8 - (waveNumber * 0.05));
    double orcChance = min(0.6, 0.2 + (waveNumber * 0.03));
    double trollChance = min(0.3, max(0, (waveNumber - 5) * 0.02));

    for (int i = 0; i < baseEnemies; i++) {
      double random = Random().nextDouble();

      if (random < goblinChance) {
        enemies.add(Goblin());
      } else if (random < goblinChance + orcChance) {
        enemies.add(Orc());
      } else if (random < goblinChance + orcChance + trollChance) {
        enemies.add(Troll());
      } else {
        enemies.add(Goblin()); // Fallback
      }
    }

    // Add boss every 5 waves
    if (waveNumber % 5 == 0) {
      enemies.add(Boss());
    }

    return enemies;
  }
}
```

### **Resource System**

#### **Gold Economy**

- **Starting Gold**: 100
- **Enemy Rewards**: 10-200 gold per enemy
- **Wave Bonus**: 50 gold per completed wave
- **Perfect Wave Bonus**: 100 gold for no lives lost

#### **Lives System**

- **Starting Lives**: 20
- **Life Loss**: 1 life per enemy reaching base
- **Game Over**: When lives reach 0
- **Life Bonus**: 5 lives every 10 waves

## Visual Design

### **Art Style**

- **Modern Fantasy**: Clean, colorful, engaging
- **Isometric Perspective**: 2.5D view for strategic gameplay
- **Smooth Animations**: 60fps gameplay animations
- **Particle Effects**: Tower attacks, enemy deaths, explosions

### **Color Palette**

```dart
// Primary Colors
const Color primaryGold = Color(0xFFFFD700);      // Gold for currency
const Color secondaryBlue = Color(0xFF4A90E2);    // Blue for UI elements
const Color accentRed = Color(0xFFE74C3C);        // Red for damage/health
const Color successGreen = Color(0xFF2ECC71);     // Green for success

// Background Colors
const Color backgroundDark = Color(0xFF2C3E50);   // Dark background
const Color backgroundLight = Color(0xFFECF0F1);  // Light background
const Color surfaceColor = Color(0xFF34495E);     // Surface elements

// Text Colors
const Color textPrimary = Color(0xFF2C3E50);      // Primary text
const Color textSecondary = Color(0xFF7F8C8D);    // Secondary text
const Color textLight = Color(0xFFFFFFFF);        // Light text
```

### **UI Elements**

- **Tower Shop**: Grid layout with tower cards
- **Upgrade Panel**: Sliding panel with upgrade options
- **Wave Info**: Animated wave counter and progress
- **Resource Display**: Gold and lives counter
- **Game Overlay**: Pause, settings, and game controls

## Audio Design

### **Sound Effects**

- **Tower Attacks**: Unique sounds for each tower type
- **Enemy Deaths**: Different sounds for each enemy type
- **UI Interactions**: Button clicks, menu navigation
- **Game Events**: Wave start, victory, defeat

### **Background Music**

- **Main Theme**: Upbeat, strategic music
- **Wave Music**: Intense music during enemy waves
- **Victory Music**: Celebratory music for completed waves
- **Defeat Music**: Somber music for game over

## Level Design

### Map 1: Forest Path

- **Theme**: Dense forest with winding paths
- **Layout**: Single path with multiple curves
- **Difficulty**: Easy, introduces basic mechanics
- **Special Features**: Natural obstacles, limited building space

### Map 2: Mountain Pass

- **Theme**: Rocky mountain terrain
- **Layout**: Multiple paths with intersections
- **Difficulty**: Medium, requires strategic thinking
- **Special Features**: Elevated areas, choke points

### Map 3: Castle Courtyard

- **Theme**: Medieval castle with stone walls
- **Layout**: Complex maze-like structure
- **Difficulty**: Hard, maximum strategic challenge
- **Special Features**: Multiple entry points, defensive positions

## Achievement System

### **Tower Mastery**

- **Archer Expert**: Complete 10 waves using only archer towers
- **Cannon Master**: Defeat 100 enemies with cannon towers
- **Magic User**: Slow 50 enemies with magic towers
- **Sniper Elite**: Get 50 critical hits with sniper towers

### **Strategic Achievements**

- **Perfect Defense**: Complete a wave without losing lives
- **Resource Manager**: Complete 5 waves with less than 50 gold
- **Speed Runner**: Complete a level in under 5 minutes
- **Tower Planner**: Place all 4 tower types in a single level

### **Progression Achievements**

- **Wave Survivor**: Complete 20 waves
- **Level Master**: Complete all 3 levels
- **Gold Collector**: Accumulate 10,000 gold
- **Enemy Slayer**: Defeat 1,000 enemies

## Technical Specifications

### **Performance Targets**

- **Frame Rate**: Consistent 60fps on all platforms
- **Memory Usage**: < 100MB on mobile devices
- **Load Times**: < 3 seconds for level loading
- **Battery Usage**: Optimized for mobile devices

### **Platform Support**

- **Mobile**: Android and iOS with touch controls
- **Web**: Browser-based with mouse/keyboard controls
- **Desktop**: Windows, macOS, Linux with mouse controls

### **Save System**

- **Progress Persistence**: Save level completion and achievements
- **Settings Storage**: Audio preferences, control settings
- **Statistics Tracking**: Game statistics and performance metrics

## User Experience

### **Onboarding**

- **Tutorial Level**: Step-by-step introduction to mechanics
- **Tooltips**: Contextual help for new features
- **Progressive Disclosure**: Introduce complexity gradually
- **Practice Mode**: Safe environment to learn mechanics

### **Accessibility**

- **Color Blind Support**: Alternative color schemes
- **Touch Targets**: Adequate size for mobile interaction
- **Audio Options**: Mute controls, volume settings
- **Text Scaling**: Adjustable text sizes

### **Feedback Systems**

- **Visual Feedback**: Damage numbers, health bars, effects
- **Audio Feedback**: Sound effects for all actions
- **Haptic Feedback**: Vibration for mobile devices
- **Progress Indicators**: Clear indication of advancement

## Design System

### Color Palette

```dart
// Game Colors
const Color primaryGold = Color(0xFFFFD700);      // Gold for currency
const Color secondaryBlue = Color(0xFF4A90E2);    // Blue for UI elements
const Color accentRed = Color(0xFFE74C3C);        // Red for damage/health
const Color successGreen = Color(0xFF2ECC71);     // Green for success

// Background Colors
const Color backgroundDark = Color(0xFF2C3E50);   // Dark background
const Color backgroundLight = Color(0xFFECF0F1);  // Light background
const Color surfaceColor = Color(0xFF34495E);     // Surface elements

// Text Colors
const Color textPrimary = Color(0xFF2C3E50);      // Primary text
const Color textSecondary = Color(0xFF7F8C8D);    // Secondary text
const Color textLight = Color(0xFFFFFFFF);        // Light text
```

### Typography

```dart
// Game Text Styles
const TextStyle headlineLarge = TextStyle(
  fontSize: 32,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.5,
);

const TextStyle titleMedium = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.15,
);

const TextStyle bodyLarge = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.5,
);

const TextStyle labelSmall = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.4,
);
```

### UI Components

#### Tower Cards

- **Size**: 80x80 pixels
- **Border Radius**: 12px
- **Shadow**: Elevation 2
- **Hover Effect**: Scale 1.05

#### Buttons

- **Primary**: Gold background, white text
- **Secondary**: Blue background, white text
- **Danger**: Red background, white text
- **Border Radius**: 8px
- **Padding**: 12px horizontal, 8px vertical

#### Progress Bars

- **Height**: 8px
- **Border Radius**: 4px
- **Background**: Light gray
- **Fill**: Context-dependent color

### Animations

- **Tower Placement**: Scale from 0.8 to 1.0 over 200ms
- **Enemy Death**: Fade out over 300ms with scale down
- **Projectile**: Linear movement with rotation
- **UI Transitions**: Slide and fade effects, 250ms duration
- **Button Hover**: Scale 1.02 over 150ms

### Responsive Design

#### Mobile (< 768px)

- **Tower Shop**: 2 columns
- **UI Elements**: Larger touch targets (48px minimum)
- **Text**: Increased font sizes for readability

#### Tablet (768px - 1024px)

- **Tower Shop**: 3 columns
- **Side Panels**: Expandable/collapsible
- **Game Area**: Optimized for landscape

#### Desktop (> 1024px)

- **Tower Shop**: 4 columns
- **Multiple Panels**: Side-by-side layout
- **Keyboard Shortcuts**: Full support

---

This game design document provides the foundation for creating an engaging, strategic tower defense game that showcases advanced Flutter development skills.
