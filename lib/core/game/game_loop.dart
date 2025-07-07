import 'package:flutter/scheduler.dart';
import '../constants/app_constants.dart';

/// Game loop controller that manages the game's update cycle at 60fps
class GameLoop {
  bool _isRunning = false;
  bool _isPaused = false;
  late Ticker _ticker;

  // Performance tracking
  double _lastFrameTime = 0.0;
  double _frameTime = 1.0 / 60.0; // Default to 60 FPS
  int _frameCount = 0;
  double _fps = 60.0;
  double _lastFpsUpdate = 0.0;

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
      _lastFrameTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
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

    // Calculate actual frame time for smooth 60 FPS
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    _frameTime = currentTime - _lastFrameTime;
    _lastFrameTime = currentTime;

    // Clamp frame time to prevent spiral of death
    if (_frameTime > 1.0 / 30.0) {
      _frameTime = 1.0 / 30.0; // Cap at 30 FPS minimum
    }

    // Update FPS counter every second
    _frameCount++;
    if (currentTime - _lastFpsUpdate >= 1.0) {
      _fps = _frameCount / (currentTime - _lastFpsUpdate);
      _frameCount = 0;
      _lastFpsUpdate = currentTime;
    }

    // Update game logic with actual frame time
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
  double get currentFPS => _fps;
  double get frameTime => _frameTime;
  int get frameCount => _frameCount;
}
