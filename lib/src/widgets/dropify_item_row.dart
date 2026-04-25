import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dropify_item.dart';

/// Displays one selectable Dropify item.
class DropifyItemRow<T> extends StatelessWidget {
  /// Creates an item row.
  const DropifyItemRow({
    super.key,
    required this.item,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  /// Item metadata displayed by this row.
  final DropifyItem<T> item;

  /// Row height.
  final double height;

  /// Whether the item is currently selected.
  final bool selected;

  /// Called when the enabled row is tapped.
  final VoidCallback? onTap;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<DropifyItem<T>>('item', item));
    properties.add(DoubleProperty('height', height));
    properties.add(
      FlagProperty('selected', value: selected, ifTrue: 'selected'),
    );
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = item.enabled
        ? theme.colorScheme.onSurface
        : theme.disabledColor;
    return Semantics(
      button: true,
      enabled: item.enabled,
      selected: selected,
      child: InkWell(
        onTap: item.enabled ? onTap : null,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
                if (selected) const Icon(Icons.check, size: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
