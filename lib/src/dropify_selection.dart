import 'dropify_item.dart';

/// The current selection mode for a Dropify field.
enum DropifySelectionMode {
  /// A single item can be selected.
  single,
}

/// Helpers for controlled single selection.
class DropifySingleSelection<T> {
  /// Creates a controlled single selection helper.
  const DropifySingleSelection(this.value);

  /// The currently selected value supplied by the parent widget.
  final T? value;

  /// Whether [item] represents the selected value.
  bool contains(DropifyItem<T> item) {
    return item.value == value || item.stableKey == value;
  }

  /// Finds the selected item metadata in [items], if present.
  DropifyItem<T>? findIn(Iterable<DropifyItem<T>> items) {
    for (final item in items) {
      if (contains(item)) {
        return item;
      }
    }
    return null;
  }
}
