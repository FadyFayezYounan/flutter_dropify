import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dropify_controller.dart';
import 'dropify_item.dart';
import 'dropify_keys.dart';
import 'dropify_selection.dart';
import 'dropify_source.dart';
import 'dropify_theme.dart';
import 'widgets/dropify_empty_row.dart';
import 'widgets/dropify_error_row.dart';
import 'widgets/dropify_field_anchor.dart';
import 'widgets/dropify_item_row.dart';
import 'widgets/dropify_loading_row.dart';
import 'widgets/dropify_overlay_panel.dart';
import 'widgets/dropify_search_input.dart';

enum _DropifyAsyncState { idle, loading, data, error }

/// Core static Dropify field with an anchored searchable menu.
class DropifyField<T> extends StatefulWidget {
  /// Creates a core Dropify field.
  const DropifyField({
    super.key,
    required this.source,
    required this.value,
    required this.onChanged,
    this.onError,
    this.controller,
    this.enabled = true,
    this.hintText,
    this.emptyText,
    this.paginationTriggerExtent = 80.0,
    this.keys = DropifyKeys.defaultKeys,
    this.theme,
  }) : assert(
         paginationTriggerExtent >= 0.0,
         'paginationTriggerExtent must be >= 0',
       );

  /// Static source displayed by this field.
  final DropifySource<T> source;

  /// Controlled selected value.
  final T? value;

  /// Called when the selected value changes.
  final ValueChanged<T?> onChanged;

  /// Called when an async source throws.
  final DropifyErrorCallback? onError;

  /// Optional controller for open, close, clear, refresh, and retry commands.
  final DropifyController? controller;

  /// Whether the field can be opened.
  final bool enabled;

  /// Placeholder text when no item is selected.
  final String? hintText;

  /// Empty-state text shown when no rows match.
  final String? emptyText;

  /// Remaining scroll extent that triggers the next page load.
  final double paginationTriggerExtent;

  /// Stable keys used by tests and robot journeys.
  final DropifyKeys keys;

  /// Optional theme overrides.
  final DropifyThemeData? theme;

  @override
  State<DropifyField<T>> createState() => _DropifyFieldState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DropifySource<T>>('source', source));
    properties.add(DiagnosticsProperty<T?>('value', value, defaultValue: null));
    properties.add(
      ObjectFlagProperty<ValueChanged<T?>>.has('onChanged', onChanged),
    );
    properties.add(
      ObjectFlagProperty<DropifyErrorCallback?>.has('onError', onError),
    );
    properties.add(
      DiagnosticsProperty<DropifyController?>('controller', controller),
    );
    properties.add(
      FlagProperty('enabled', value: enabled, ifFalse: 'disabled'),
    );
    properties.add(StringProperty('hintText', hintText, defaultValue: null));
    properties.add(StringProperty('emptyText', emptyText, defaultValue: null));
    properties.add(
      DoubleProperty('paginationTriggerExtent', paginationTriggerExtent),
    );
    properties.add(DiagnosticsProperty<DropifyKeys>('keys', keys));
    properties.add(DiagnosticsProperty<DropifyThemeData?>('theme', theme));
  }
}

class _DropifyFieldState<T> extends State<DropifyField<T>> {
  late final MenuController _menuController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ScrollController _scrollController;
  Timer? _debounceTimer;
  List<DropifyItem<T>> _asyncItems = List<DropifyItem<T>>.empty();
  _DropifyAsyncState _asyncState = _DropifyAsyncState.idle;
  bool _hasMorePages = false;
  Object? _nextPageKey;
  String? _loadingFirstPageQuery;
  String? _loadedFirstPageQuery;
  bool _isLoadingNextPage = false;
  bool _hasNextPageError = false;
  int _requestToken = 0;
  bool _isOpen = false;

  DropifyThemeData get _resolvedTheme {
    return DropifyThemeData.fallback.merge(widget.theme);
  }

  List<DropifyItem<T>> get _visibleItems {
    if (widget.source.isRemote) {
      return _asyncItems;
    }
    return widget.source.filter(DropifyQuery(_searchController.text));
  }

  DropifyItem<T>? get _selectedItem {
    final items = widget.source.isRemote ? _asyncItems : widget.source.items;
    return DropifySingleSelection<T>(widget.value).findIn(items);
  }

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
    _searchController = TextEditingController()
      ..addListener(_handleSearchChanged);
    _searchFocusNode = FocusNode();
    _scrollController = ScrollController()..addListener(_handleScrollChanged);
    widget.controller?.addListener(_handleControllerCommand);
  }

  @override
  void didUpdateWidget(covariant DropifyField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isOpen) {
      _menuController.close();
    }
    if (oldWidget.source != widget.source && widget.source.isRemote) {
      _resetRemoteState();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleControllerCommand);
      widget.controller?.addListener(_handleControllerCommand);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _requestToken += 1;
    widget.controller?.removeListener(_handleControllerCommand);
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _scrollController
      ..removeListener(_handleScrollChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _resetRemoteState() {
    _asyncItems = List<DropifyItem<T>>.empty();
    _asyncState = _DropifyAsyncState.idle;
    _hasMorePages = false;
    _nextPageKey = null;
    _loadingFirstPageQuery = null;
    _loadedFirstPageQuery = null;
    _isLoadingNextPage = false;
    _hasNextPageError = false;
  }

  void _handleControllerCommand() {
    switch (widget.controller?.command) {
      case DropifyControllerCommand.open:
        if (!_isOpen && widget.enabled) {
          _menuController.open();
        }
      case DropifyControllerCommand.close:
        if (_isOpen) {
          _menuController.close();
        }
      case DropifyControllerCommand.clearSearch:
        final wasEmpty = _searchController.text.isEmpty;
        if (!wasEmpty) {
          _searchController.clear();
        }
        if (_isOpen) {
          if (widget.source.isRemote && wasEmpty) {
            _loadRemoteItems(force: true);
          } else if (!widget.source.isRemote) {
            setState(() {});
          }
        }
      case DropifyControllerCommand.refresh || DropifyControllerCommand.retry:
        if (_isOpen && widget.source.isRemote) {
          if (widget.source.isPaginated && _hasNextPageError) {
            _loadNextPage(force: true);
          } else {
            _loadRemoteItems(force: true);
          }
        }
      case null:
        return;
    }
  }

  void _handleSearchChanged() {
    if (!_isOpen) {
      return;
    }
    if (widget.source.isRemote) {
      _scheduleRemoteLoad();
    } else {
      setState(() {});
    }
  }

  void _scheduleRemoteLoad() {
    _debounceTimer?.cancel();
    final debounceDuration = widget.source.debounceDuration;
    if (debounceDuration == Duration.zero) {
      _loadRemoteItems();
      return;
    }
    _debounceTimer = Timer(debounceDuration, _loadRemoteItems);
  }

  void _loadRemoteItems({bool force = false}) {
    if (widget.source.isPaginated) {
      _loadFirstPage(force: force);
    } else {
      _loadAsyncItems();
    }
  }

  Future<void> _loadAsyncItems() async {
    if (!widget.source.isAsync || !_isOpen || !widget.enabled) {
      return;
    }
    final token = _requestToken + 1;
    _requestToken = token;
    setState(() {
      _asyncState = _DropifyAsyncState.loading;
    });

    final query = DropifyQuery(_searchController.text);
    try {
      final items = await widget.source.load(query);
      if (!mounted || token != _requestToken || !_isOpen) {
        return;
      }
      setState(() {
        _asyncItems = items;
        _asyncState = _DropifyAsyncState.data;
      });
    } catch (error, stackTrace) {
      if (!mounted || token != _requestToken || !_isOpen) {
        return;
      }
      widget.onError?.call(error, stackTrace);
      setState(() {
        _asyncItems = List<DropifyItem<T>>.empty();
        _asyncState = _DropifyAsyncState.error;
      });
    }
  }

  void _handleScrollChanged() {
    if (!widget.source.isPaginated || !_scrollController.hasClients) {
      return;
    }
    if (_scrollController.position.extentAfter <=
        widget.paginationTriggerExtent) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage({bool force = false}) async {
    if (!widget.source.isPaginated || !_isOpen || !widget.enabled) {
      return;
    }
    final query = DropifyQuery(_searchController.text);
    if (!force &&
        _asyncState == _DropifyAsyncState.data &&
        _loadedFirstPageQuery == query.text) {
      return;
    }
    if (_asyncState == _DropifyAsyncState.loading &&
        _loadingFirstPageQuery == query.text) {
      return;
    }
    final token = _requestToken + 1;
    _requestToken = token;
    setState(() {
      _asyncItems = List<DropifyItem<T>>.empty();
      _asyncState = _DropifyAsyncState.loading;
      _hasMorePages = false;
      _nextPageKey = null;
      _loadingFirstPageQuery = query.text;
      _loadedFirstPageQuery = null;
      _isLoadingNextPage = false;
      _hasNextPageError = false;
    });

    try {
      final result = await widget.source.loadPage(
        DropifyPageRequest(query: query),
      );
      if (!mounted || token != _requestToken || !_isOpen) {
        return;
      }
      setState(() {
        _asyncItems = List<DropifyItem<T>>.unmodifiable(result.items);
        _asyncState = _DropifyAsyncState.data;
        _hasMorePages = result.hasMore;
        _nextPageKey = result.nextPageKey;
        _loadingFirstPageQuery = null;
        _loadedFirstPageQuery = query.text;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
    } catch (error, stackTrace) {
      if (!mounted || token != _requestToken || !_isOpen) {
        return;
      }
      widget.onError?.call(error, stackTrace);
      setState(() {
        _asyncItems = List<DropifyItem<T>>.empty();
        _asyncState = _DropifyAsyncState.error;
        _loadingFirstPageQuery = null;
      });
    }
  }

  Future<void> _loadNextPage({bool force = false}) async {
    if (!widget.source.isPaginated ||
        !_isOpen ||
        !widget.enabled ||
        !_hasMorePages ||
        _isLoadingNextPage ||
        (_hasNextPageError && !force)) {
      return;
    }
    final token = _requestToken;
    final pageKey = _nextPageKey;
    setState(() {
      _isLoadingNextPage = true;
      _hasNextPageError = false;
    });

    final query = DropifyQuery(_searchController.text);
    try {
      final result = await widget.source.loadPage(
        DropifyPageRequest(query: query, pageKey: pageKey),
      );
      if (!mounted || token != _requestToken || !_isOpen) {
        return;
      }
      setState(() {
        _asyncItems = List<DropifyItem<T>>.unmodifiable(<DropifyItem<T>>[
          ..._asyncItems,
          ...result.items,
        ]);
        _hasMorePages = result.hasMore;
        _nextPageKey = result.nextPageKey;
        _isLoadingNextPage = false;
      });
    } catch (error, stackTrace) {
      if (!mounted || token != _requestToken || !_isOpen) {
        return;
      }
      widget.onError?.call(error, stackTrace);
      setState(() {
        _isLoadingNextPage = false;
        _hasNextPageError = true;
      });
    }
  }

  void _toggleMenu() {
    if (!widget.enabled) {
      return;
    }
    if (_isOpen) {
      _menuController.close();
    } else {
      _menuController.open();
    }
  }

  void _handleOpen() {
    setState(() {
      _isOpen = true;
    });
    if (widget.source.isRemote) {
      _loadRemoteItems();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isOpen) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _handleClose() {
    if (!_isOpen) {
      return;
    }
    setState(() {
      _isOpen = false;
      _searchController.clear();
      if (widget.source.isPaginated) {
        _hasNextPageError = false;
        _isLoadingNextPage = false;
      }
    });
    _debounceTimer?.cancel();
    _requestToken += 1;
  }

  void _handleSelect(DropifyItem<T> item) {
    if (!item.enabled) {
      return;
    }
    widget.onChanged(item.value);
    _menuController.close();
  }

  int get _paginationRowCount {
    if (_isLoadingNextPage || _hasNextPageError || !_hasMorePages) {
      return 1;
    }
    return 0;
  }

  Widget _buildPaginationRow(DropifyThemeData theme) {
    if (_isLoadingNextPage) {
      return DropifyLoadingRow(
        key: widget.keys.paginationLoadingRow,
        text: 'Loading more',
        height: theme.itemHeight!,
      );
    }
    if (_hasNextPageError) {
      return DropifyErrorRow(
        key: widget.keys.paginationErrorRow,
        text: 'Unable to load more',
        height: theme.itemHeight!,
        retryKey: widget.keys.paginationRetryButton,
        onRetry: () => _loadNextPage(force: true),
      );
    }
    return DropifyEmptyRow(
      key: widget.keys.paginationEndRow,
      text: 'End of list',
      height: theme.itemHeight!,
    );
  }

  Widget _buildOverlay(BuildContext context, RawMenuOverlayInfo info) {
    final theme = _resolvedTheme;
    final anchorRect = info.anchorRect;
    final overlaySize = info.overlaySize;
    final maxMenuHeight = theme.maxMenuHeight!;
    final menuWidth = math.max(anchorRect.width, 160.0);
    final left = math.min(
      math.max(anchorRect.left, 8.0),
      math.max(8.0, overlaySize.width - menuWidth - 8.0),
    );
    final top = math.min(
      anchorRect.bottom + 4.0,
      math.max(8.0, overlaySize.height - maxMenuHeight - 8.0),
    );

    return Positioned(
      left: left,
      top: top,
      width: menuWidth,
      child: TapRegion(
        groupId: info.tapRegionGroupId,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxMenuHeight),
          child: DropifyOverlayPanel(
            key: widget.keys.menu,
            elevation: theme.menuElevation!,
            borderRadius: theme.menuBorderRadius!,
            padding: theme.menuPadding!,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                final visibleItems = _visibleItems;
                final showLoading =
                    widget.source.isRemote &&
                    _asyncState == _DropifyAsyncState.loading;
                final showError =
                    widget.source.isRemote &&
                    _asyncState == _DropifyAsyncState.error;
                final paginationRowCount = widget.source.isPaginated
                    ? _paginationRowCount
                    : 0;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropifySearchInput(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      inputKey: widget.keys.searchInput,
                      hintText: theme.searchHintText!,
                    ),
                    const SizedBox(height: 8.0),
                    Flexible(
                      child: showLoading
                          ? DropifyLoadingRow(
                              key: widget.keys.loadingRow,
                              text: 'Loading',
                              height: theme.itemHeight!,
                            )
                          : showError
                          ? DropifyErrorRow(
                              key: widget.keys.errorRow,
                              text: 'Unable to load items',
                              height: theme.itemHeight!,
                              retryKey: widget.keys.retryButton,
                              onRetry: _loadAsyncItems,
                            )
                          : visibleItems.isEmpty
                          ? DropifyEmptyRow(
                              key: widget.keys.emptyRow,
                              text: widget.emptyText ?? theme.emptyText!,
                              height: theme.itemHeight!,
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount:
                                  visibleItems.length + paginationRowCount,
                              itemBuilder: (context, index) {
                                if (index >= visibleItems.length) {
                                  return _buildPaginationRow(theme);
                                }
                                final item = visibleItems[index];
                                return DropifyItemRow<T>(
                                  key: widget.keys.item(
                                    item.stableKey ?? item.value,
                                  ),
                                  item: item,
                                  height: theme.itemHeight!,
                                  selected: DropifySingleSelection<T>(
                                    widget.value,
                                  ).contains(item),
                                  onTap: () => _handleSelect(item),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: _menuController,
      consumeOutsideTaps: true,
      onOpen: _handleOpen,
      onClose: _handleClose,
      overlayBuilder: _buildOverlay,
      builder: (context, controller, child) {
        return DropifyFieldAnchor(
          key: widget.keys.field,
          enabled: widget.enabled,
          isOpen: _isOpen,
          onTap: _toggleMenu,
          label: _selectedItem?.label,
          hintText: widget.hintText,
        );
      },
    );
  }
}
