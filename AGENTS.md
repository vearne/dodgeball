# AGENTS.md - Dodgeball Game Development Guide

This file provides guidelines for agentic coding agents working on this Flutter game project.

## Build/Test Commands

```bash
# Run development build (macOS)
flutter run -d macos

# Run release build
flutter run -d macos --release

# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Analyze code for issues
flutter analyze

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

## Project Overview

- **Type**: 2D dodgeball game using Flutter + Flame engine
- **SDK**: Dart ^3.8.1
- **Key Dependencies**: flame (^1.30.1), flame_audio (^2.10.0), flame_forge2d (^0.19.2+2)
- **Platforms**: macOS, Windows, iOS, Android, mobile
- **Language**: Chinese comments, localized UI (English/Chinese)

## Code Style Guidelines

### Import Organization

Order imports in this sequence:
1. Dart SDK imports (e.g., `import 'dart:math';`)
2. Package imports (e.g., `import 'package:flame/components.dart';`)
3. Relative/project imports (e.g., `import 'game/audio_manager.dart';`)

Example:
```dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'game/audio_manager.dart';
import 'screens/mission_selection_screen.dart';
```

### Naming Conventions

- **Classes**: PascalCase (e.g., `MissionDodgeballGame`, `PlayerComponent`)
- **Private members**: Leading underscore (e.g., `_elapsedTime`, `_audioManager`)
- **Public fields**: camelCase (e.g., `playerTeam`, `enemyTeam`)
- **Constants**: lowerCamelCase for local constants, UPPER_SNAKE_CASE for static constants
  - Local: `const playerRadius = 16.0;`
  - Static: `static const double wallThickness = 60.0;`
- **Files**: snake_case (e.g., `player_component.dart`, `mission_map.dart`)
- **Enums**: PascalCase for enum type, lowerCamelCase for values
  ```dart
  enum GameState { playing, redWins, blueWins, paused }
  ```

### Formatting

- Use standard Dart formatting (`dart format .`)
- 2-space indentation
- Prefer explicit types for public API, inferred types for local variables
- Trailing commas for multi-line arguments

### Type Safety

- Use explicit types for function parameters and return types
- Avoid `dynamic` - use specific types or `Object?` when necessary
- Use nullable types (`Type?`) when values can be null
- Never use `as any`, `@ts-ignore`, or type suppression
- Initialize non-nullable fields at declaration or in constructor

### Error Handling

- Never use empty catch blocks
- Log errors appropriately (use `print()` for debugging, consider logging library for production)
- Handle specific exceptions when possible
- Provide meaningful error messages
- Use try-catch for operations that may fail (file I/O, async operations, etc.)

```dart
try {
  await MissionMapManager.deleteMap(map.id);
} catch (e) {
  // Handle error gracefully with user feedback
}
```

### Documentation

- Use triple-slash comments `///` for public API documentation
- Use double-slash comments `//` for inline explanations
- Comments in Chinese for code explanations
- UI strings use localization keys (see `gen_l10n/app_localizations.dart`)

### State Management

- Use `ValueNotifier<T>` for reactive state in Flutter widgets
- For game components, manage state in component fields
- Use `setState()` in StatefulWidget subclasses
- Avoid global mutable state; prefer dependency injection or singletons

### File Organization

```
lib/
├── main.dart              # App entry point
├── game/                  # Game logic & components
│   ├── *component.dart    # Game entities (Player, Ball, etc.)
│   ├── game_mode.dart     # Enums & types
│   └── *_config.dart      # Configuration classes
├── screens/               # Flutter UI screens
│   └── *_screen.dart      # Screen widgets
└── gen_l10n/             # Generated localization files
```

### Lint Rules

- Uses `flutter_lints` package (see `analysis_options.yaml`)
- To disable a lint temporarily: `// ignore: name_of_lint` or `// ignore_for_file: name_of_lint`
- Fix lint warnings before committing code
- Run `flutter analyze` to check for issues

### Testing

- Use `flutter_test` package
- Widget tests: Use `WidgetTester` and `testWidgets()`
- Mock external dependencies when necessary
- Test both success and error paths
- Keep tests focused and fast

### Game-Specific Patterns

- **Physics**: Use Forge2D (flame_forge2d) with pixel units (1 unit = 1 meter)
- **Components**: Extend `BodyComponent` for physics entities, `Component` for non-physics
- **Coordinates**: Use `Vector2` for positions, `Vector2.zero()` for origin
- **Resolution**: Fixed resolution 1380x720 (configured in CameraComponent)
- **Areas**: Red team (left), Blue team (right), separated by center gap
- **Async Initialization**: Use `await super.onLoad()` before component setup

### Localization

- UI strings use `AppLocalizations.of(context)!`
- Supported locales: English (`en`), Chinese (`zh`)
- Run `flutter gen-l10n` to generate localization files after modifying `.arb` files

### Common Patterns

**Async initialization**:
```dart
@override
Future<void> onLoad() async {
  await super.onLoad();
  // Component initialization here
}
```

**Component lifecycle**:
- `onLoad()`: One-time initialization
- `update(dt)`: Per-frame game logic
- `onRemove()`: Cleanup when removed from game

**Contact callbacks** (Forge2D):
```dart
class MyComponent extends BodyComponent with ContactCallbacks {
  @override
  void onLoad() {
    super.onLoad();
    body.userData = this; // Required for collision callbacks
    setupCollisionCallbacks();
  }
}
```

### Performance Guidelines

- Object pooling for frequently spawned/destroyed entities (balls, particles)
- Avoid creating objects in `update()` loop
- Use `TimerComponent` for timed events instead of manual tracking
- Profile with `flutter devtools` when optimizing

## Quick Reference

- **Entry point**: `lib/main.dart`
- **Main game class**: `lib/game/mission_dodgeball_game.dart`
- **Player component**: `lib/game/player_component.dart`
- **Map editor**: `lib/screens/map_editor_screen.dart`
- **Config**: `pubspec.yaml`, `analysis_options.yaml`

## Notes for AI Agents

1. Always run `flutter analyze` on changed files before completing tasks
2. Test on macOS target: `flutter run -d macos`
3. Check for existing patterns before introducing new approaches
4. The codebase uses Chinese comments - preserve this convention
5. Game coordinates are in pixels, centered (not top-left anchored in all cases)
6. Physical simulation uses Forge2D - understand BodyType: static/kinematic/dynamic
