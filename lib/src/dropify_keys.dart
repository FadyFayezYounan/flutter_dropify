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

  /// Loading row selector.
  static const Key loadingRow = ValueKey<String>('dropify.loadingRow');

  /// Error row selector.
  static const Key errorRow = ValueKey<String>('dropify.errorRow');

  /// Retry button selector.
  static const Key retryButton = ValueKey<String>('dropify.retryButton');

  /// Pagination loading row selector.
  static const Key paginationLoadingRow = ValueKey<String>(
    'dropify.paginationLoadingRow',
  );

  /// Pagination error row selector.
  static const Key paginationErrorRow = ValueKey<String>(
    'dropify.paginationErrorRow',
  );

  /// Pagination retry button selector.
  static const Key paginationRetryButton = ValueKey<String>(
    'dropify.paginationRetryButton',
  );

  /// No-more-items row selector.
  static const Key noMoreItemsRow = ValueKey<String>('dropify.noMoreItemsRow');

  /// Returns an item-row selector for [identity].
  static Key itemRow(Object? identity) {
    return ValueKey<String>('dropify.itemRow.$identity');
  }

  /// Returns a selected-chip selector for [identity].
  static Key selectedChip(Object? identity) {
    return ValueKey<String>('dropify.selectedChip.$identity');
  }
}
