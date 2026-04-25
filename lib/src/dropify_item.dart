import 'package:flutter/foundation.dart';

/// A selectable item displayed by Dropify dropdown widgets.
@immutable
class DropifyItem<T> {
  /// Creates a [DropifyItem].
  const DropifyItem({
    required this.value,
    required this.label,
    this.enabled = true,
    this.id,
  });

  /// The typed value emitted when this item is selected.
  final T value;

  /// The visible label used by the default row and filter UI.
  final String label;

  /// Whether this item can be selected.
  final bool enabled;

  /// Optional stable identity used for keys and duplicate checks.
  final Object? id;

  /// The stable identity for this item, falling back to [value].
  Object? get identity => id ?? value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DropifyItem<T> &&
            other.value == value &&
            other.label == label &&
            other.enabled == enabled &&
            other.id == id;
  }

  @override
  int get hashCode => Object.hash(value, label, enabled, id);

  @override
  String toString() {
    return 'DropifyItem<$T>(value: $value, label: $label, enabled: $enabled, id: $id)';
  }
}

/// Asserts that visible Dropify items have unique identities.
bool debugAssertUniqueDropifyIdentities<T>(Iterable<DropifyItem<T>> items) {
  assert(() {
    final seen = <Object?>{};
    for (final item in items) {
      final identity = item.identity;
      if (!seen.add(identity)) {
        throw FlutterError(
          'Dropify visible items must have unique identities. Duplicate identity: $identity.',
        );
      }
    }
    return true;
  }());
  return true;
}
