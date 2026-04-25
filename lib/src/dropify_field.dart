import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dropify_item.dart';
import 'dropify_keys.dart';
import 'dropify_selection.dart';
import 'dropify_source.dart';
import 'dropify_theme.dart';
import 'widgets/dropify_empty_row.dart';
import 'widgets/dropify_field_anchor.dart';
import 'widgets/dropify_item_row.dart';
import 'widgets/dropify_overlay_panel.dart';
import 'widgets/dropify_search_input.dart';

/// Core static Dropify field with an anchored searchable menu.
class DropifyField<T> extends StatefulWidget {
  /// Creates a core Dropify field.
  const DropifyField({
    super.key,
    required this.source,
    required this.value,
    required this.onChanged,
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
  bool _isOpen = false;

  DropifyThemeData get _resolvedTheme {
    return DropifyThemeData.fallback.merge(widget.theme);
  }

  List<DropifyItem<T>> get _visibleItems {
    return widget.source.filter(DropifyQuery(_searchController.text));
  }

  DropifyItem<T>? get _selectedItem {
    return DropifySingleSelection<T>(widget.value).findIn(widget.source.items);
  }

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
    _searchController = TextEditingController()
      ..addListener(_handleSearchChanged);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant DropifyField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _isOpen) {
      _menuController.close();
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (_isOpen) {
      setState(() {});
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
                      child: visibleItems.isEmpty
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
