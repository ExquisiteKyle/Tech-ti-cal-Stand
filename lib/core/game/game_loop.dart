import 'package:flutter/scheduler.dart';
import '../constants/app_constants.dart';

/// Game loop controller that manages the game's update cycle at 60fps
class GameLoop {
  bool _isRunning = false;
  bool _isPaused = false;
  late Ticker _ticker;

  // Game loop callbacks
  VoidCallback? onUpdate;
  VoidCallback? onRender;

  GameLoop() {
    _ticker = Ticker(_onTick);
  }

  /// Start the game loop
  void start() {
    if (!_isRunning) {
      _isRunning = true;
      _isPaused = false;
      _ticker.start();
    }
  }

  /// Stop the game loop
  void stop() {
    if (_isRunning) {
      _isRunning = false;
      _ticker.stop();
    }
  }

  /// Pause the game loop
  void pause() {
    _isPaused = true;
  }

  /// Resume the game loop
  void resume() {
    _isPaused = false;
  }

  /// Toggle pause state
  void togglePause() {
    _isPaused = !_isPaused;
  }

  void _onTick(Duration elapsed) {
    if (!_isRunning || _isPaused) return;

    // Update game logic
    onUpdate?.call();

    // Render frame
    onRender?.call();
  }

  /// Dispose of the game loop
  void dispose() {
    stop();
    _ticker.dispose();
  }

  // Getters
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  double get targetFPS => AppConstants.targetFPS;
}
