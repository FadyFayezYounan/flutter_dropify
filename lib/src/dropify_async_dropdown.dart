import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'dropify_builder.dart';
import 'dropify_builders.dart';
import 'dropify_controller.dart';
import 'dropify_source.dart';

/// A typed async dropdown with searchable single-select and multi-select modes.
class DropifyAsyncDropdown<T> extends StatelessWidget {
  /// Creates a single-select [DropifyAsyncDropdown].
  const DropifyAsyncDropdown({
    super.key,
    required this.loader,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.controller,
    this.placeholder = 'Select an option',
    this.searchHintText = 'Search',
    this.emptyText = 'No options found',
    this.searchDebounceDuration = const Duration(milliseconds: 300),
    this.onError,
    this.fieldBuilder,
    this.searchBuilder,
    this.itemBuilder,
    this.selectedBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.dataBuilder,
    this.overlayBuilder,
    this.menuHeaderBuilder,
    this.menuFooterBuilder,
  }) : values = const <Never>[],
       onMultiChanged = null,
       selectedItemsBuilder = null,
       multi = false;

  /// Creates a multi-select [DropifyAsyncDropdown].
  const DropifyAsyncDropdown.multi({
    super.key,
    required this.loader,
    required this.values,
    required ValueChanged<List<T>>? onChanged,
    this.enabled = true,
    this.controller,
    this.placeholder = 'Select options',
    this.searchHintText = 'Search',
    this.emptyText = 'No options found',
    this.searchDebounceDuration = const Duration(milliseconds: 300),
    this.onError,
    this.fieldBuilder,
    this.searchBuilder,
    this.itemBuilder,
    this.selectedItemsBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.dataBuilder,
    this.overlayBuilder,
    this.menuHeaderBuilder,
    this.menuFooterBuilder,
  }) : value = null,
       onChanged = null,
       onMultiChanged = onChanged,
       selectedBuilder = null,
       multi = true;

  /// Loads items for the current query.
  final DropifyAsyncLoader<T> loader;

  /// Controlled single-select value.
  final T? value;

  /// Controlled multi-select values.
  final List<T> values;

  /// Called when the single-select value changes.
  final ValueChanged<T?>? onChanged;

  /// Called when the multi-select values change.
  final ValueChanged<List<T>>? onMultiChanged;

  /// Whether the dropdown can be opened and selected.
  final bool enabled;

  /// Optional interaction controller.
  final DropifyController? controller;

  /// Placeholder text for the default field.
  final String placeholder;

  /// Hint text for the default search field.
  final String searchHintText;

  /// Text for the default empty state.
  final String emptyText;

  /// Debounce duration for async search loads.
  final Duration searchDebounceDuration;

  /// Called when [loader] fails.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Custom field builder.
  final DropifyFieldBuilder<T>? fieldBuilder;

  /// Custom search builder.
  final DropifySearchBuilder? searchBuilder;

  /// Custom item row builder.
  final DropifyItemBuilder<T>? itemBuilder;

  /// Custom selected single display builder.
  final DropifySelectedBuilder<T>? selectedBuilder;

  /// Custom selected multi display builder.
  final DropifySelectedItemsBuilder<T>? selectedItemsBuilder;

  /// Custom loading state builder.
  final DropifyLoadingBuilder? loadingBuilder;

  /// Custom empty state builder.
  final DropifyEmptyBuilder? emptyBuilder;

  /// Custom error state builder.
  final DropifyErrorBuilder? errorBuilder;

  /// Advanced data body builder.
  final DropifyDataBuilder<T>? dataBuilder;

  /// Custom overlay shell builder.
  final DropifyOverlayBuilder? overlayBuilder;

  /// Optional menu header builder.
  final DropifyMenuBuilder? menuHeaderBuilder;

  /// Optional menu footer builder.
  final DropifyMenuBuilder? menuFooterBuilder;

  final bool multi;

  @override
  Widget build(BuildContext context) {
    return DropifyBuilder<T>(
      source: DropifySource<T>.async(loader: loader),
      value: value,
      values: values,
      onChanged: onChanged,
      onMultiChanged: onMultiChanged,
      multi: multi,
      enabled: enabled,
      controller: controller,
      placeholder: placeholder,
      searchHintText: searchHintText,
      emptyText: emptyText,
      fieldBuilder: fieldBuilder,
      searchBuilder: searchBuilder,
      itemBuilder: itemBuilder,
      selectedBuilder: selectedBuilder,
      selectedItemsBuilder: selectedItemsBuilder,
      loadingBuilder: loadingBuilder,
      emptyBuilder: emptyBuilder,
      errorBuilder: errorBuilder,
      dataBuilder: dataBuilder,
      overlayBuilder: overlayBuilder,
      menuHeaderBuilder: menuHeaderBuilder,
      menuFooterBuilder: menuFooterBuilder,
      searchDebounceDuration: searchDebounceDuration,
      onError: onError,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('multi', value: multi, ifTrue: 'multi'));
    properties.add(
      FlagProperty('enabled', value: enabled, ifFalse: 'disabled'),
    );
    properties.add(StringProperty('placeholder', placeholder));
    properties.add(StringProperty('searchHintText', searchHintText));
    properties.add(StringProperty('emptyText', emptyText));
    properties.add(
      DiagnosticsProperty<Duration>(
        'searchDebounceDuration',
        searchDebounceDuration,
      ),
    );
    properties.add(
      ObjectFlagProperty<ValueChanged<T?>?>.has('onChanged', onChanged),
    );
    properties.add(
      ObjectFlagProperty<ValueChanged<List<T>>?>.has(
        'onMultiChanged',
        onMultiChanged,
      ),
    );
  }
}
