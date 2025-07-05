import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tower.dart';

/// Tower selection state
class TowerSelectionState {
  final TowerType? selectedTowerType;
  final bool isSelecting;

  const TowerSelectionState({this.selectedTowerType, this.isSelecting = false});

  TowerSelectionState copyWith({
    TowerType? selectedTowerType,
    bool? isSelecting,
  }) => TowerSelectionState(
    selectedTowerType: selectedTowerType ?? this.selectedTowerType,
    isSelecting: isSelecting ?? this.isSelecting,
  );

  TowerSelectionState clear() => const TowerSelectionState();
}

/// Tower selection state notifier
class TowerSelectionNotifier extends StateNotifier<TowerSelectionState> {
  TowerSelectionNotifier() : super(const TowerSelectionState());

  /// Select a tower type for placement
  void selectTower(TowerType towerType) {
    state = TowerSelectionState(
      selectedTowerType: towerType,
      isSelecting: true,
    );
  }

  /// Clear tower selection
  void clearSelection() {
    state = state.clear();
  }

  /// Check if a tower type is currently selected
  bool isSelected(TowerType towerType) {
    return state.selectedTowerType == towerType && state.isSelecting;
  }
}

/// Provider for tower selection state
final towerSelectionProvider =
    StateNotifierProvider<TowerSelectionNotifier, TowerSelectionState>(
      (ref) => TowerSelectionNotifier(),
    );
