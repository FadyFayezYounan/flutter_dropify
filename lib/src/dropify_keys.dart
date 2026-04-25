import 'package:flutter/widgets.dart';

/// Stable keys used by Dropify widgets and journey tests.
class DropifyKeys {
  /// Creates a namespaced set of Dropify keys.
  const DropifyKeys({this.namespace = 'dropify'});

  /// The default key namespace used by Dropify widgets.
  static const DropifyKeys defaultKeys = DropifyKeys();

  /// Prefix used to keep keys unique when multiple dropdowns are on screen.
  final String namespace;

  /// Key for the tappable field anchor.
  ValueKey<String> get field => ValueKey<String>('$namespace.field');

  /// Key for the menu overlay container.
  ValueKey<String> get menu => ValueKey<String>('$namespace.menu');

  /// Key for the search input.
  ValueKey<String> get searchInput =>
      ValueKey<String>('$namespace.searchInput');

  /// Key for the empty-state row.
  ValueKey<String> get emptyRow => ValueKey<String>('$namespace.emptyRow');

  /// Returns the key for an item row.
  ValueKey<String> item(Object? value) {
    return ValueKey<String>('$namespace.item.$value');
  }
}
