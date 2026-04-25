import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import 'dropify_builders.dart';
import 'dropify_controller.dart';
import 'dropify_item.dart';
import 'dropify_keys.dart';
import 'dropify_pagination.dart';
import 'dropify_query.dart';
import 'dropify_source.dart';

/// Low-level builder-first dropdown widget used by Dropify convenience widgets.
class DropifyBuilder<T> extends StatefulWidget {
  /// Creates a [DropifyBuilder].
  const DropifyBuilder({
    super.key,
    required this.source,
    this.value,
    this.values = const <Never>[],
    this.onChanged,
    this.onMultiChanged,
    this.multi = false,
    this.enabled = true,
    this.controller,
    this.placeholder = 'Select an option',
    this.searchHintText = 'Search',
    this.emptyText = 'No options found',
    this.fieldBuilder,
    this.searchBuilder,
    this.itemBuilder,
    this.selectedBuilder,
    this.selectedItemsBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.dataBuilder,
    this.overlayBuilder,
    this.menuHeaderBuilder,
    this.menuFooterBuilder,
    this.searchDebounceDuration = const Duration(milliseconds: 300),
    this.onError,
    this.loadMoreBuilder,
    this.loadMoreErrorBuilder,
    this.noMoreItemsBuilder,
  });

  /// Static item source for this slice.
  final DropifySource<T> source;

  /// Controlled single-select value.
  final T? value;

  /// Controlled multi-select values.
  final List<T> values;

  /// Called when the single-select value changes.
  final ValueChanged<T?>? onChanged;

  /// Called when the multi-select values change.
  final ValueChanged<List<T>>? onMultiChanged;

  /// Whether this builder is in multi-select mode.
  final bool multi;

  /// Whether the widget can be opened and selected.
  final bool enabled;

  /// Optional interaction controller.
  final DropifyController? controller;

  /// Placeholder text for the default field.
  final String placeholder;

  /// Hint text for the default search field.
  final String searchHintText;

  /// Text for the default empty state.
  final String emptyText;

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

  /// Custom empty state builder.
  final DropifyEmptyBuilder? emptyBuilder;

  /// Custom loading state builder.
  final DropifyLoadingBuilder? loadingBuilder;

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

  /// Debounce duration for async search loads.
  final Duration searchDebounceDuration;

  /// Called when an async loader fails.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Custom paginated load-more state builder.
  final DropifyLoadMoreBuilder? loadMoreBuilder;

  /// Custom paginated load-more error builder.
  final DropifyLoadMoreErrorBuilder? loadMoreErrorBuilder;

  /// Custom paginated end-of-list builder.
  final DropifyNoMoreItemsBuilder? noMoreItemsBuilder;

  @override
  State<DropifyBuilder<T>> createState() => _DropifyBuilderState<T>();

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

class _DropifyBuilderState<T> extends State<DropifyBuilder<T>> {
  late final MenuController _menuController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ScrollController _pagingScrollController;
  final Map<T, DropifyItem<T>> _knownItemsByValue = <T, DropifyItem<T>>{};
  Timer? _searchDebounceTimer;
  PagingState<Object?, DropifyItem<T>> _pagingState = PagingState(
    hasNextPage: true,
    isLoading: false,
  );
  Object? _nextPageKey;
  var _asyncItems = <DropifyItem<T>>[];
  var _isLoading = false;
  var _hasLoadedAsyncItems = false;
  var _requestSerial = 0;
  Object? _loadError;
  StackTrace? _loadStackTrace;
  DropifyQuery? _loadingQuery;
  DropifyQuery? _failedQuery;
  StackTrace? _pagingErrorStackTrace;
  DropifyQuery? _pagingQuery;
  var _suppressSearchListener = false;
  var _isPagingRequestInFlight = false;
  bool _isOpen = false;

  bool get _canInteract {
    final hasCallback = widget.multi
        ? widget.onMultiChanged != null
        : widget.onChanged != null;
    return widget.enabled && hasCallback;
  }

  DropifyQuery get _query => DropifyQuery.fromRaw(_searchController.text);

  List<DropifyItem<T>> get _visibleItems {
    if (widget.source.isPaginated) {
      final items = _pagingState.items ?? <DropifyItem<T>>[];
      assert(debugAssertUniqueDropifyIdentities(items));
      return List<DropifyItem<T>>.unmodifiable(items);
    }
    if (widget.source.isAsync) {
      assert(debugAssertUniqueDropifyIdentities(_asyncItems));
      return List<DropifyItem<T>>.unmodifiable(_asyncItems);
    }
    final items = widget.source.resolve(_query);
    assert(debugAssertUniqueDropifyIdentities(items));
    return items;
  }

  Iterable<DropifyItem<T>> get _availableItems {
    return widget.source.isAsync
        ? _knownItemsByValue.values
        : widget.source.isPaginated
        ? _knownItemsByValue.values
        : widget.source.items;
  }

  DropifyItem<T>? get _selectedItem {
    for (final item in _availableItems) {
      if (item.value == widget.value) {
        return item;
      }
    }
    return null;
  }

  List<DropifyItem<T>> get _selectedItems {
    final selected = <DropifyItem<T>>[];
    for (final item in _availableItems) {
      if (widget.values.contains(item.value)) {
        selected.add(item);
      }
    }
    return List<DropifyItem<T>>.unmodifiable(selected);
  }

  @override
  void initState() {
    super.initState();
    assert(
      !widget.searchDebounceDuration.isNegative,
      'Dropify searchDebounceDuration must not be negative.',
    );
    _menuController = MenuController();
    _searchController = TextEditingController();
    _searchController.addListener(_handleSearchTextChanged);
    _searchFocusNode = FocusNode();
    _pagingScrollController = ScrollController();
    _nextPageKey = widget.source.firstPageKey;
    _pagingQuery = _query;
    widget.controller?.addListener(_handleControllerCommand);
  }

  @override
  void didUpdateWidget(covariant DropifyBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerCommand);
      widget.controller?.addListener(_handleControllerCommand);
    }
    if (!_canInteract && _isOpen) {
      _close();
    }
    final sourceModeChanged =
        oldWidget.source.isAsync != widget.source.isAsync ||
        oldWidget.source.isPaginated != widget.source.isPaginated;
    if (sourceModeChanged && _isOpen) {
      if (widget.source.isAsync) {
        _loadAsyncItems(_query);
      } else if (widget.source.isPaginated) {
        _resetPaging(_query);
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerCommand);
    _searchDebounceTimer?.cancel();
    _pagingScrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.removeListener(_handleSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleControllerCommand() {
    final command = widget.controller?.takePendingCommand();
    switch (command) {
      case DropifyControllerCommand.open:
        _open();
      case DropifyControllerCommand.close:
        _close();
      case DropifyControllerCommand.toggle:
        _toggle();
      case DropifyControllerCommand.search:
        _setSearchText(widget.controller?.takePendingSearchText() ?? '');
      case DropifyControllerCommand.refresh:
        if (widget.source.isAsync) {
          _loadAsyncItems(_query);
        } else if (widget.source.isPaginated) {
          _resetPaging(_query);
        }
      case DropifyControllerCommand.retry:
        if (widget.source.isAsync) {
          _retryAsyncLoad();
        } else if (widget.source.isPaginated) {
          _retryPagingLoad();
        }
      case null:
        break;
    }
  }

  void _open() {
    if (!_canInteract) {
      return;
    }
    _menuController.open();
  }

  void _close() {
    _menuController.close();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _handleOpen() {
    if (_isOpen) {
      return;
    }
    setState(() {
      _isOpen = true;
    });
    if (widget.source.isAsync && !_hasLoadedAsyncItems && !_isLoading) {
      _loadAsyncItems(_query);
    } else if (widget.source.isPaginated && _pagingState.pages == null) {
      _loadNextPage();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isOpen) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _handleClose() {
    _searchDebounceTimer?.cancel();
    if (widget.source.isAsync || widget.source.isPaginated) {
      _requestSerial++;
    }
    setState(() {
      _isOpen = false;
      if (widget.source.isPaginated) {
        _isPagingRequestInFlight = false;
      }
      _setSearchText('', notify: false);
    });
  }

  void _handleSearchTextChanged() {
    if (_suppressSearchListener) {
      return;
    }
    if (widget.source.isPaginated && _isOpen) {
      setState(() {});
      _schedulePaginatedSearch();
      return;
    }
    if (widget.source.isAsync && _isOpen) {
      setState(() {});
      _scheduleAsyncSearch();
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _setSearchText(String text, {bool notify = true}) {
    if (_searchController.text == text) {
      return;
    }
    _suppressSearchListener = !notify;
    _searchController.text = text;
    _searchController.selection = TextSelection.collapsed(offset: text.length);
    _suppressSearchListener = false;
    if (notify && mounted) {
      setState(() {});
      if (widget.source.isAsync && _isOpen) {
        _scheduleAsyncSearch();
      } else if (widget.source.isPaginated && _isOpen) {
        _schedulePaginatedSearch();
      }
    }
  }

  void _scheduleAsyncSearch() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(widget.searchDebounceDuration, () {
      if (mounted && _isOpen) {
        _loadAsyncItems(_query);
      }
    });
  }

  void _schedulePaginatedSearch() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(widget.searchDebounceDuration, () {
      if (mounted && _isOpen) {
        _resetPaging(_query);
      }
    });
  }

  Future<void> _loadAsyncItems(DropifyQuery query) async {
    final loader = widget.source.asyncLoader;
    if (loader == null) {
      return;
    }
    if (_isLoading && _loadingQuery == query) {
      return;
    }

    _searchDebounceTimer?.cancel();
    final requestId = ++_requestSerial;
    setState(() {
      _isLoading = true;
      _loadError = null;
      _loadStackTrace = null;
      _loadingQuery = query;
      _failedQuery = null;
    });

    try {
      final items = await Future<List<DropifyItem<T>>>.sync(
        () => loader(query),
      );
      if (!mounted || requestId != _requestSerial || !_isOpen) {
        return;
      }
      assert(debugAssertUniqueDropifyIdentities(items));
      for (final item in items) {
        _knownItemsByValue[item.value] = item;
      }
      setState(() {
        _asyncItems = List<DropifyItem<T>>.unmodifiable(items);
        _isLoading = false;
        _hasLoadedAsyncItems = true;
        _loadingQuery = null;
      });
    } catch (error, stackTrace) {
      if (!mounted || requestId != _requestSerial || !_isOpen) {
        return;
      }
      widget.onError?.call(error, stackTrace);
      setState(() {
        _isLoading = false;
        _hasLoadedAsyncItems = true;
        _loadingQuery = null;
        _loadError = error;
        _loadStackTrace = stackTrace;
        _failedQuery = query;
      });
    }
  }

  void _retryAsyncLoad() {
    _loadAsyncItems(_failedQuery ?? _query);
  }

  void _resetPaging(DropifyQuery query) {
    _searchDebounceTimer?.cancel();
    _requestSerial++;
    if (_pagingScrollController.hasClients) {
      _pagingScrollController.jumpTo(0);
    }
    setState(() {
      _pagingQuery = query;
      _nextPageKey = widget.source.firstPageKey;
      _pagingErrorStackTrace = null;
      _isPagingRequestInFlight = false;
      _pagingState = PagingState<Object?, DropifyItem<T>>(
        hasNextPage: true,
        isLoading: false,
      );
    });
    if (_isOpen) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage({bool reserved = false}) async {
    final loader = widget.source.paginatedLoader;
    if (loader == null ||
        (!reserved && _isPagingRequestInFlight) ||
        _pagingState.isLoading ||
        !_pagingState.hasNextPage) {
      return;
    }

    final query = _pagingQuery ?? _query;
    final pageKey = _pagingState.pages == null
        ? widget.source.firstPageKey
        : _nextPageKey;
    final requestId = ++_requestSerial;
    _isPagingRequestInFlight = true;
    setState(() {
      _pagingErrorStackTrace = null;
      _pagingState = _pagingState.copyWith(isLoading: true, error: null);
    });

    try {
      final result = await Future<DropifyPageResult<T, Object?>>.sync(
        () =>
            loader(DropifyPageRequest<Object?>(query: query, pageKey: pageKey)),
      );
      if (!mounted ||
          requestId != _requestSerial ||
          !_isOpen ||
          query != _pagingQuery) {
        _isPagingRequestInFlight = false;
        return;
      }
      final pages = <List<DropifyItem<T>>>[
        ...?_pagingState.pages,
        List<DropifyItem<T>>.unmodifiable(result.items),
      ];
      final allItems = pages.expand((page) => page);
      assert(debugAssertUniqueDropifyIdentities(allItems));
      for (final item in result.items) {
        _knownItemsByValue[item.value] = item;
      }
      setState(() {
        _isPagingRequestInFlight = false;
        _nextPageKey = result.nextPageKey;
        _pagingState = _pagingState.copyWith(
          pages: pages,
          keys: <Object?>[...?_pagingState.keys, pageKey],
          hasNextPage: result.hasMore,
          isLoading: false,
          error: null,
        );
      });
    } catch (error, stackTrace) {
      if (!mounted ||
          requestId != _requestSerial ||
          !_isOpen ||
          query != _pagingQuery) {
        _isPagingRequestInFlight = false;
        return;
      }
      widget.onError?.call(error, stackTrace);
      setState(() {
        _isPagingRequestInFlight = false;
        _pagingErrorStackTrace = stackTrace;
        _pagingState = _pagingState.copyWith(isLoading: false, error: error);
      });
    }
  }

  void _retryPagingLoad() {
    _loadNextPage();
  }

  void _selectItem(DropifyItem<T> item) {
    if (!_canInteract || !item.enabled) {
      return;
    }

    if (widget.multi) {
      final values = List<T>.of(widget.values);
      if (values.contains(item.value)) {
        values.remove(item.value);
      } else {
        values.add(item.value);
      }
      widget.onMultiChanged?.call(List<T>.unmodifiable(values));
      return;
    }

    widget.onChanged?.call(item.value);
    _close();
  }

  void _clearAll() {
    if (!_canInteract || !widget.multi) {
      return;
    }
    widget.onMultiChanged?.call(List<T>.unmodifiable(<T>[]));
  }

  void _selectVisible() {
    if (!_canInteract || !widget.multi) {
      return;
    }
    final values = List<T>.of(widget.values);
    for (final item in _visibleItems) {
      if (item.enabled && !values.contains(item.value)) {
        values.add(item.value);
      }
    }
    widget.onMultiChanged?.call(List<T>.unmodifiable(values));
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _menuController,
      consumeOutsideTaps: false,
      onOpen: _handleOpen,
      onClose: _handleClose,
      overlayBuilder: _buildOverlay,
      builder: (context, controller, child) {
        return KeyedSubtree(
          key: DropifyKeys.field,
          child: _buildField(context),
        );
      },
    );
  }

  Widget _buildField(BuildContext context) {
    final state = DropifyFieldState<T>(
      isOpen: _isOpen,
      isEnabled: _canInteract,
      isMultiSelect: widget.multi,
      query: _query,
      selectedItem: _selectedItem,
      selectedItems: _selectedItems,
      open: _open,
      close: _close,
      toggle: _toggle,
      clearSearch: () => _setSearchText(''),
    );
    final customBuilder = widget.fieldBuilder;
    if (customBuilder != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _canInteract ? _toggle : null,
        child: customBuilder(context, state),
      );
    }

    final child = widget.multi
        ? _buildDefaultMultiSelection(context)
        : _buildDefaultSingleSelection(context);
    return Semantics(
      button: true,
      enabled: _canInteract,
      expanded: _isOpen,
      child: InkWell(
        onTap: _canInteract ? _toggle : null,
        child: InputDecorator(
          decoration: InputDecoration(
            enabled: _canInteract,
            border: const OutlineInputBorder(),
            suffixIcon: Icon(
              _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDefaultSingleSelection(BuildContext context) {
    final customBuilder = widget.selectedBuilder;
    if (customBuilder != null) {
      return customBuilder(
        context,
        DropifySelectedState<T>(item: _selectedItem),
      );
    }
    final item = _selectedItem;
    return Text(item?.label ?? widget.placeholder);
  }

  Widget _buildDefaultMultiSelection(BuildContext context) {
    final customBuilder = widget.selectedItemsBuilder;
    final selectedItems = _selectedItems;
    if (customBuilder != null) {
      return customBuilder(
        context,
        DropifySelectedItemsState<T>(items: selectedItems),
      );
    }
    if (selectedItems.isEmpty) {
      return Text(widget.placeholder);
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        for (final item in selectedItems)
          Chip(
            key: DropifyKeys.selectedChip(item.identity),
            label: Text(item.label),
          ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context, RawMenuOverlayInfo info) {
    final query = _query;
    final visibleItems = _visibleItems;
    Widget content = KeyedSubtree(
      key: DropifyKeys.menuOverlay,
      child: TapRegion(
        groupId: info.tapRegionGroupId,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: info.anchorRect.width,
              maxWidth: info.anchorRect.width,
              maxHeight: 320,
            ),
            child: _DropifyMenu<T>(
              search: _buildSearch(context),
              header: widget.menuHeaderBuilder?.call(context),
              footer: widget.menuFooterBuilder?.call(context),
              actions: widget.multi ? _buildMultiActions(context) : null,
              body: _buildBody(context, visibleItems, query),
            ),
          ),
        ),
      ),
    );

    final customOverlayBuilder = widget.overlayBuilder;
    if (customOverlayBuilder != null) {
      content = customOverlayBuilder(
        context,
        DropifyOverlayState(isOpen: _isOpen, query: query),
        content,
      );
    }

    return Positioned(
      left: info.anchorRect.left,
      top: info.anchorRect.bottom + 4,
      width: info.anchorRect.width,
      child: content,
    );
  }

  Widget _buildSearch(BuildContext context) {
    final state = DropifySearchState(
      controller: _searchController,
      focusNode: _searchFocusNode,
      query: _query,
      clear: () => _setSearchText(''),
    );
    final customBuilder = widget.searchBuilder;
    if (customBuilder != null) {
      return KeyedSubtree(
        key: DropifyKeys.searchInput,
        child: customBuilder(context, state),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        key: DropifyKeys.searchInput,
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: widget.searchHintText,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildMultiActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8,
        children: <Widget>[
          TextButton(
            key: DropifyKeys.selectAll,
            onPressed: _canInteract ? _selectVisible : null,
            child: const Text('Select visible'),
          ),
          TextButton(
            key: DropifyKeys.clearAll,
            onPressed: _canInteract ? _clearAll : null,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<DropifyItem<T>> visibleItems,
    DropifyQuery query,
  ) {
    final customDataBuilder = widget.dataBuilder;
    final error = _loadError;
    final stackTrace = _loadStackTrace;
    if (widget.source.isPaginated) {
      return _buildPaginatedBody(context, query);
    }
    if (_isLoading && widget.source.isAsync) {
      final customLoadingBuilder = widget.loadingBuilder;
      return Padding(
        key: DropifyKeys.loadingRow,
        padding: const EdgeInsets.all(16),
        child:
            customLoadingBuilder?.call(
              context,
              DropifyLoadingState(query: query),
            ) ??
            const Text('Loading options...'),
      );
    }
    if (error != null && stackTrace != null && widget.source.isAsync) {
      final customErrorBuilder = widget.errorBuilder;
      return Padding(
        key: DropifyKeys.errorRow,
        padding: const EdgeInsets.all(16),
        child:
            customErrorBuilder?.call(
              context,
              DropifyErrorState(
                query: _failedQuery ?? query,
                error: error,
                stackTrace: stackTrace,
                retry: _retryAsyncLoad,
              ),
            ) ??
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Could not load options'),
                TextButton(
                  key: DropifyKeys.retryButton,
                  onPressed: _retryAsyncLoad,
                  child: const Text('Retry'),
                ),
              ],
            ),
      );
    }
    if (customDataBuilder != null && visibleItems.isNotEmpty) {
      return Flexible(
        child: customDataBuilder(
          context,
          DropifyDataState<T>(items: visibleItems, query: query),
        ),
      );
    }
    if (visibleItems.isEmpty) {
      final customEmptyBuilder = widget.emptyBuilder;
      return Padding(
        key: DropifyKeys.emptyRow,
        padding: const EdgeInsets.all(16),
        child:
            customEmptyBuilder?.call(
              context,
              DropifyEmptyState(query: query),
            ) ??
            Text(widget.emptyText),
      );
    }
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: visibleItems.length,
        itemBuilder: (context, index) {
          final item = visibleItems[index];
          return KeyedSubtree(
            key: DropifyKeys.itemRow(item.identity),
            child: _buildItem(context, item),
          );
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, DropifyItem<T> item) {
    final isSelected = widget.multi
        ? widget.values.contains(item.value)
        : widget.value == item.value;
    final isDisabled = !_canInteract || !item.enabled;
    final state = DropifyItemState<T>(
      item: item,
      isSelected: isSelected,
      isHighlighted: false,
      isDisabled: isDisabled,
      select: () => _selectItem(item),
    );
    final customBuilder = widget.itemBuilder;
    if (customBuilder != null) {
      return Semantics(
        selected: isSelected,
        enabled: !isDisabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isDisabled ? null : () => _selectItem(item),
          child: customBuilder(context, state),
        ),
      );
    }

    return Semantics(
      selected: isSelected,
      enabled: !isDisabled,
      child: ListTile(
        enabled: !isDisabled,
        selected: isSelected,
        leading: widget.multi
            ? Checkbox(
                value: isSelected,
                onChanged: isDisabled ? null : (_) => _selectItem(item),
              )
            : null,
        title: Text(item.label),
        onTap: isDisabled ? null : () => _selectItem(item),
      ),
    );
  }

  Widget _buildPaginatedBody(BuildContext context, DropifyQuery query) {
    if (_pagingState.pages == null) {
      final error = _pagingState.error;
      final stackTrace = _pagingErrorStackTrace;
      if (error != null && stackTrace != null) {
        final customErrorBuilder = widget.errorBuilder;
        return Padding(
          key: DropifyKeys.errorRow,
          padding: const EdgeInsets.all(16),
          child:
              customErrorBuilder?.call(
                context,
                DropifyErrorState(
                  query: query,
                  error: error,
                  stackTrace: stackTrace,
                  retry: _retryPagingLoad,
                ),
              ) ??
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Could not load options'),
                  TextButton(
                    key: DropifyKeys.retryButton,
                    onPressed: _retryPagingLoad,
                    child: const Text('Retry'),
                  ),
                ],
              ),
        );
      }
      final customLoadingBuilder = widget.loadingBuilder;
      return Padding(
        key: DropifyKeys.loadingRow,
        padding: const EdgeInsets.all(16),
        child:
            customLoadingBuilder?.call(
              context,
              DropifyLoadingState(query: query),
            ) ??
            const Text('Loading options...'),
      );
    }

    return Flexible(
      child: PagedListView<Object?, DropifyItem<T>>(
        scrollController: _pagingScrollController,
        shrinkWrap: true,
        state: _pagingState,
        fetchNextPage: _loadNextPage,
        builderDelegate: PagedChildBuilderDelegate<DropifyItem<T>>(
          invisibleItemsThreshold: 1,
          itemBuilder: (context, item, index) {
            return KeyedSubtree(
              key: DropifyKeys.itemRow(item.identity),
              child: _buildItem(context, item),
            );
          },
          firstPageProgressIndicatorBuilder: (context) {
            final customLoadingBuilder = widget.loadingBuilder;
            return Padding(
              key: DropifyKeys.loadingRow,
              padding: const EdgeInsets.all(16),
              child:
                  customLoadingBuilder?.call(
                    context,
                    DropifyLoadingState(query: query),
                  ) ??
                  const Text('Loading options...'),
            );
          },
          firstPageErrorIndicatorBuilder: (context) {
            final error = _pagingState.error;
            final stackTrace = _pagingErrorStackTrace;
            final customErrorBuilder = widget.errorBuilder;
            return Padding(
              key: DropifyKeys.errorRow,
              padding: const EdgeInsets.all(16),
              child: error != null && stackTrace != null
                  ? customErrorBuilder?.call(
                          context,
                          DropifyErrorState(
                            query: query,
                            error: error,
                            stackTrace: stackTrace,
                            retry: _retryPagingLoad,
                          ),
                        ) ??
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text('Could not load options'),
                            TextButton(
                              key: DropifyKeys.retryButton,
                              onPressed: _retryPagingLoad,
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                  : const Text('Could not load options'),
            );
          },
          noItemsFoundIndicatorBuilder: (context) {
            final customEmptyBuilder = widget.emptyBuilder;
            return Padding(
              key: DropifyKeys.emptyRow,
              padding: const EdgeInsets.all(16),
              child:
                  customEmptyBuilder?.call(
                    context,
                    DropifyEmptyState(query: query),
                  ) ??
                  Text(widget.emptyText),
            );
          },
          newPageProgressIndicatorBuilder: (context) {
            final customLoadMoreBuilder = widget.loadMoreBuilder;
            return Padding(
              key: DropifyKeys.paginationLoadingRow,
              padding: const EdgeInsets.all(16),
              child:
                  customLoadMoreBuilder?.call(
                    context,
                    DropifyLoadMoreState(query: query),
                  ) ??
                  const Text('Loading more options...'),
            );
          },
          newPageErrorIndicatorBuilder: (context) {
            final error = _pagingState.error;
            final stackTrace = _pagingErrorStackTrace;
            final customLoadMoreErrorBuilder = widget.loadMoreErrorBuilder;
            return Padding(
              key: DropifyKeys.paginationErrorRow,
              padding: const EdgeInsets.all(16),
              child: error != null && stackTrace != null
                  ? customLoadMoreErrorBuilder?.call(
                          context,
                          DropifyLoadMoreErrorState(
                            query: query,
                            error: error,
                            stackTrace: stackTrace,
                            retry: _retryPagingLoad,
                          ),
                        ) ??
                        TextButton(
                          key: DropifyKeys.paginationRetryButton,
                          onPressed: _retryPagingLoad,
                          child: const Text('Retry loading more'),
                        )
                  : const Text('Could not load more options'),
            );
          },
          noMoreItemsIndicatorBuilder: (context) {
            final customNoMoreItemsBuilder = widget.noMoreItemsBuilder;
            return Padding(
              key: DropifyKeys.noMoreItemsRow,
              padding: const EdgeInsets.all(16),
              child:
                  customNoMoreItemsBuilder?.call(
                    context,
                    DropifyNoMoreItemsState(query: query),
                  ) ??
                  const Text('No more options'),
            );
          },
        ),
      ),
    );
  }
}

class _DropifyMenu<T> extends StatelessWidget {
  const _DropifyMenu({
    required this.search,
    required this.body,
    this.header,
    this.footer,
    this.actions,
  });

  final Widget search;
  final Widget body;
  final Widget? header;
  final Widget? footer;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[search, ?header, ?actions, body, ?footer],
    );
  }
}
