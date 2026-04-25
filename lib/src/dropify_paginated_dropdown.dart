import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'dropify_builder.dart';
import 'dropify_builders.dart';
import 'dropify_controller.dart';
import 'dropify_pagination.dart';
import 'dropify_source.dart';

/// A typed paginated dropdown with searchable single-select and multi-select modes.
class DropifyPaginatedDropdown<T, PageKey> extends StatelessWidget {
  /// Creates a single-select [DropifyPaginatedDropdown].
  const DropifyPaginatedDropdown({
    super.key,
    required this.pageLoader,
    required this.value,
    required this.onChanged,
    this.firstPageKey,
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
    this.loadMoreBuilder,
    this.loadMoreErrorBuilder,
    this.noMoreItemsBuilder,
  }) : values = const <Never>[],
       onMultiChanged = null,
       selectedItemsBuilder = null,
       multi = false;

  /// Creates a multi-select [DropifyPaginatedDropdown].
  const DropifyPaginatedDropdown.multi({
    super.key,
    required this.pageLoader,
    required this.values,
    required ValueChanged<List<T>>? onChanged,
    this.firstPageKey,
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
    this.loadMoreBuilder,
    this.loadMoreErrorBuilder,
    this.noMoreItemsBuilder,
  }) : value = null,
       onChanged = null,
       onMultiChanged = onChanged,
       selectedBuilder = null,
       multi = true;

  /// Loads one page for the current query and page key.
  final DropifyPaginatedLoader<T, PageKey> pageLoader;

  /// First page key, often null for cursor-based APIs.
  final PageKey? firstPageKey;

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

  /// Debounce duration for search-triggered page resets.
  final Duration searchDebounceDuration;

  /// Called when [pageLoader] fails.
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

  /// Custom load-more state builder.
  final DropifyLoadMoreBuilder? loadMoreBuilder;

  /// Custom load-more error builder.
  final DropifyLoadMoreErrorBuilder? loadMoreErrorBuilder;

  /// Custom end-of-pagination builder.
  final DropifyNoMoreItemsBuilder? noMoreItemsBuilder;

  final bool multi;

  @override
  Widget build(BuildContext context) {
    return DropifyBuilder<T>(
      source: DropifySource<T>.paginated(
        firstPageKey: firstPageKey,
        loader: (request) async {
          final result = await pageLoader(
            DropifyPageRequest<PageKey>(
              query: request.query,
              pageKey: request.pageKey as PageKey?,
            ),
          );
          return DropifyPageResult<T, Object?>(
            items: result.items,
            nextPageKey: result.nextPageKey,
            hasMore: result.hasMore,
          );
        },
      ),
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
      loadMoreBuilder: loadMoreBuilder,
      loadMoreErrorBuilder: loadMoreErrorBuilder,
      noMoreItemsBuilder: noMoreItemsBuilder,
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
