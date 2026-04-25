import 'package:flutter/widgets.dart';

import 'dropify_item.dart';
import 'dropify_query.dart';

/// Builds the closed field anchor for a Dropify widget.
typedef DropifyFieldBuilder<T> =
    Widget Function(BuildContext context, DropifyFieldState<T> state);

/// Builds the search control for a Dropify menu.
typedef DropifySearchBuilder =
    Widget Function(BuildContext context, DropifySearchState state);

/// Builds a single item row for a Dropify menu.
typedef DropifyItemBuilder<T> =
    Widget Function(BuildContext context, DropifyItemState<T> state);

/// Builds the selected value display for a single-select Dropify field.
typedef DropifySelectedBuilder<T> =
    Widget Function(BuildContext context, DropifySelectedState<T> state);

/// Builds the selected values display for a multi-select Dropify field.
typedef DropifySelectedItemsBuilder<T> =
    Widget Function(BuildContext context, DropifySelectedItemsState<T> state);

/// Builds an empty menu state.
typedef DropifyEmptyBuilder =
    Widget Function(BuildContext context, DropifyEmptyState state);

/// Builds an advanced replacement for the data menu body.
typedef DropifyDataBuilder<T> =
    Widget Function(BuildContext context, DropifyDataState<T> state);

/// Builds an optional overlay shell around menu content.
typedef DropifyOverlayBuilder =
    Widget Function(
      BuildContext context,
      DropifyOverlayState state,
      Widget child,
    );

/// Builds optional header or footer menu content.
typedef DropifyMenuBuilder = Widget Function(BuildContext context);

/// State passed to [DropifyFieldBuilder].
@immutable
class DropifyFieldState<T> {
  /// Creates a [DropifyFieldState].
  const DropifyFieldState({
    required this.isOpen,
    required this.isEnabled,
    required this.isMultiSelect,
    required this.query,
    required this.selectedItem,
    required this.selectedItems,
    required this.open,
    required this.close,
    required this.toggle,
    required this.clearSearch,
  });

  /// Whether the menu is open.
  final bool isOpen;

  /// Whether user interaction is enabled.
  final bool isEnabled;

  /// Whether this field is in multi-select mode.
  final bool isMultiSelect;

  /// Current search query.
  final DropifyQuery query;

  /// Current selected item for single-select mode.
  final DropifyItem<T>? selectedItem;

  /// Current selected items for multi-select mode.
  final List<DropifyItem<T>> selectedItems;

  /// Opens the menu.
  final VoidCallback open;

  /// Closes the menu.
  final VoidCallback close;

  /// Toggles the menu.
  final VoidCallback toggle;

  /// Clears the search query.
  final VoidCallback clearSearch;
}

/// State passed to [DropifySearchBuilder].
@immutable
class DropifySearchState {
  /// Creates a [DropifySearchState].
  const DropifySearchState({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.clear,
  });

  /// Controller for the search input.
  final TextEditingController controller;

  /// Focus node for the search input.
  final FocusNode focusNode;

  /// Current query.
  final DropifyQuery query;

  /// Clears the search text.
  final VoidCallback clear;
}

/// State passed to [DropifyItemBuilder].
@immutable
class DropifyItemState<T> {
  /// Creates a [DropifyItemState].
  const DropifyItemState({
    required this.item,
    required this.isSelected,
    required this.isHighlighted,
    required this.isDisabled,
    required this.select,
  });

  /// The item represented by this row.
  final DropifyItem<T> item;

  /// Whether the item is selected.
  final bool isSelected;

  /// Whether the item is highlighted.
  final bool isHighlighted;

  /// Whether the item is disabled.
  final bool isDisabled;

  /// Selects or toggles the item.
  final VoidCallback select;
}

/// State passed to [DropifySelectedBuilder].
@immutable
class DropifySelectedState<T> {
  /// Creates a [DropifySelectedState].
  const DropifySelectedState({required this.item});

  /// The selected item, if one is visible to Dropify.
  final DropifyItem<T>? item;
}

/// State passed to [DropifySelectedItemsBuilder].
@immutable
class DropifySelectedItemsState<T> {
  /// Creates a [DropifySelectedItemsState].
  const DropifySelectedItemsState({required this.items});

  /// Selected items visible to Dropify.
  final List<DropifyItem<T>> items;
}

/// State passed to [DropifyEmptyBuilder].
@immutable
class DropifyEmptyState {
  /// Creates a [DropifyEmptyState].
  const DropifyEmptyState({required this.query});

  /// Current query for the empty state.
  final DropifyQuery query;
}

/// State passed to [DropifyDataBuilder].
@immutable
class DropifyDataState<T> {
  /// Creates a [DropifyDataState].
  const DropifyDataState({required this.items, required this.query});

  /// Visible items.
  final List<DropifyItem<T>> items;

  /// Current query.
  final DropifyQuery query;
}

/// State passed to [DropifyOverlayBuilder].
@immutable
class DropifyOverlayState {
  /// Creates a [DropifyOverlayState].
  const DropifyOverlayState({required this.isOpen, required this.query});

  /// Whether the menu is open.
  final bool isOpen;

  /// Current query.
  final DropifyQuery query;
}
