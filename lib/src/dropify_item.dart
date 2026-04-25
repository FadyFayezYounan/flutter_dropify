/// A typed value shown by a Dropify dropdown.
///
/// Equality uses [stableKey] when supplied, otherwise [value]. Provide a
/// stable key when two distinct values can compare equal or when value equality
/// is not stable across rebuilds.
class DropifyItem<T> {
  /// Creates a typed dropdown item.
  const DropifyItem({
    required this.value,
    required this.label,
    this.enabled = true,
    this.stableKey,
  });

  /// The application value represented by this item.
  final T value;

  /// The human-readable label used for display and default filtering.
  final String label;

  /// Whether this item can be selected.
  final bool enabled;

  /// Optional stable identity for equality, keys, and selection matching.
  final Object? stableKey;

  Object? get _identity => stableKey ?? value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DropifyItem<T> && other._identity == _identity;
  }

  @override
  int get hashCode => Object.hash(T, _identity);

  @override
  String toString() {
    return 'DropifyItem<$T>(value: $value, label: $label, enabled: $enabled)';
  }
}
