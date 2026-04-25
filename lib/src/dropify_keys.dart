import 'package:flutter/widgets.dart';

/// Stable selectors used by Dropify tests and user journey tests.
abstract final class DropifyKeys {
  /// Field anchor selector.
  static const Key field = ValueKey<String>('dropify.field');

  /// Search input selector.
  static const Key searchInput = ValueKey<String>('dropify.searchInput');

  /// Menu overlay selector.
  static const Key menuOverlay = ValueKey<String>('dropify.menuOverlay');

  /// Select-all action selector.
  static const Key selectAll = ValueKey<String>('dropify.selectAll');

  /// Clear-all action selector.
  static const Key clearAll = ValueKey<String>('dropify.clearAll');

  /// Empty row selector.
  static const Key emptyRow = ValueKey<String>('dropify.emptyRow');

  /// Returns an item-row selector for [identity].
  static Key itemRow(Object? identity) {
    return ValueKey<String>('dropify.itemRow.$identity');
  }

  /// Returns a selected-chip selector for [identity].
  static Key selectedChip(Object? identity) {
    return ValueKey<String>('dropify.selectedChip.$identity');
  }
}
