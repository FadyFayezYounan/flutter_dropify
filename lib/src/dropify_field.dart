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
    this.keys = DropifyKeys.defaultKeys,
    this.theme,
  });

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
    properties.add(DiagnosticsProperty<DropifyKeys>('keys', keys));
    properties.add(DiagnosticsProperty<DropifyThemeData?>('theme', theme));
  }
}

class _DropifyFieldState<T> extends State<DropifyField<T>> {
  late final MenuController _menuController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  Timer? _debounceTimer;
  List<DropifyItem<T>> _asyncItems = List<DropifyItem<T>>.empty();
  _DropifyAsyncState _asyncState = _DropifyAsyncState.idle;
  int _requestToken = 0;
  bool _isOpen = false;

  DropifyThemeData get _resolvedTheme {
    return DropifyThemeData.fallback.merge(widget.theme);
  }

  List<DropifyItem<T>> get _visibleItems {
    if (widget.source.isAsync) {
      return _asyncItems;
    }
    return widget.source.filter(DropifyQuery(_searchController.text));
  }

  DropifyItem<T>? get _selectedItem {
    final items = widget.source.isAsync ? _asyncItems : widget.source.items;
    return DropifySingleSelection<T>(widget.value).findIn(items);
  }

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
    _searchController = TextEditingController()
      ..addListener(_handleSearchChanged);
    _searchFocusNode = FocusNode();
    widget.controller?.addListener(_handleControllerCommand);
  }

  @override
  void didUpdateWidget(covariant DropifyField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isOpen) {
      _menuController.close();
    }
    if (oldWidget.source != widget.source && widget.source.isAsync) {
      _asyncItems = List<DropifyItem<T>>.empty();
      _asyncState = _DropifyAsyncState.idle;
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
    _searchFocusNode.dispose();
    super.dispose();
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
          if (widget.source.isAsync && wasEmpty) {
            _loadAsyncItems();
          } else if (!widget.source.isAsync) {
            setState(() {});
          }
        }
      case DropifyControllerCommand.refresh || DropifyControllerCommand.retry:
        if (_isOpen && widget.source.isAsync) {
          _loadAsyncItems();
        }
      case null:
        return;
    }
  }

  void _handleSearchChanged() {
    if (!_isOpen) {
      return;
    }
    if (widget.source.isAsync) {
      _scheduleAsyncLoad();
    } else {
      setState(() {});
    }
  }

  void _scheduleAsyncLoad() {
    _debounceTimer?.cancel();
    final debounceDuration = widget.source.debounceDuration;
    if (debounceDuration == Duration.zero) {
      _loadAsyncItems();
      return;
    }
    _debounceTimer = Timer(debounceDuration, _loadAsyncItems);
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
    if (widget.source.isAsync) {
      _loadAsyncItems();
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
                    widget.source.isAsync &&
                    _asyncState == _DropifyAsyncState.loading;
                final showError =
                    widget.source.isAsync &&
                    _asyncState == _DropifyAsyncState.error;
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
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: visibleItems.length,
                              itemBuilder: (context, index) {
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
