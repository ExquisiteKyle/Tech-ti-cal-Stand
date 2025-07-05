import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tower.dart';

/// Tower selection state
class TowerSelectionState {
  final TowerType? selectedTowerType;
  final bool isSelecting;
  final Tower? selectedTower; // For upgrading existing towers

  const TowerSelectionState({
    this.selectedTowerType,
    this.isSelecting = false,
    this.selectedTower,
  });

  TowerSelectionState copyWith({
    TowerType? selectedTowerType,
    bool? isSelecting,
    Tower? selectedTower,
  }) => TowerSelectionState(
    selectedTowerType: selectedTowerType ?? this.selectedTowerType,
    isSelecting: isSelecting ?? this.isSelecting,
    selectedTower: selectedTower ?? this.selectedTower,
  );

  TowerSelectionState clear() => const TowerSelectionState();

  /// Check if we're in tower placement mode
  bool get isPlacingTower => isSelecting && selectedTowerType != null;

  /// Check if we have a tower selected for upgrade
  bool get hasTowerSelected => selectedTower != null;
}

/// Tower selection state notifier
class TowerSelectionNotifier extends StateNotifier<TowerSelectionState> {
  TowerSelectionNotifier() : super(const TowerSelectionState());

  /// Select a tower type for placement
  void selectTower(TowerType towerType) {
    state = TowerSelectionState(
      selectedTowerType: towerType,
      isSelecting: true,
      selectedTower: null, // Clear any selected tower when placing new one
    );
  }

  /// Select an existing tower for upgrade
  void selectExistingTower(Tower tower) {
    state = TowerSelectionState(
      selectedTowerType: null,
      isSelecting: false,
      selectedTower: tower,
    );
  }

  /// Clear tower selection
  void clearSelection() {
    state = state.clear();
  }

  /// Check if a tower type is currently selected for placement
  bool isSelected(TowerType towerType) {
    return state.selectedTowerType == towerType && state.isSelecting;
  }

  /// Check if a specific tower is currently selected
  bool isTowerSelected(Tower tower) {
    return state.selectedTower?.id == tower.id;
  }
}

/// Provider for tower selection state
final towerSelectionProvider =
    StateNotifierProvider<TowerSelectionNotifier, TowerSelectionState>(
      (ref) => TowerSelectionNotifier(),
    );
