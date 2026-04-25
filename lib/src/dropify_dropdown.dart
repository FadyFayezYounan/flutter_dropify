import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'dropify_field.dart';
import 'dropify_item.dart';
import 'dropify_keys.dart';
import 'dropify_source.dart';
import 'dropify_theme.dart';

/// A static, searchable, single-select Dropify dropdown.
class DropifyDropdown<T> extends StatelessWidget {
  /// Creates a static single-select dropdown.
  const DropifyDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.hintText,
    this.emptyText,
    this.keys = DropifyKeys.defaultKeys,
    this.theme,
  });

  /// Static items shown by the dropdown.
  final List<DropifyItem<T>> items;

  /// Controlled selected value.
  final T? value;

  /// Called when the selected value changes.
  final ValueChanged<T?> onChanged;

  /// Whether the dropdown can be opened.
  final bool enabled;

  /// Placeholder text shown when no item is selected.
  final String? hintText;

  /// Empty-state text shown when the current search has no matches.
  final String? emptyText;

  /// Stable keys used by tests and robots.
  final DropifyKeys keys;

  /// Optional theme overrides.
  final DropifyThemeData? theme;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<DropifyItem<T>>('items', items));
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

  @override
  Widget build(BuildContext context) {
    return DropifyField<T>(
      source: DropifySource<T>.static(items: items),
      value: value,
      onChanged: onChanged,
      enabled: enabled,
      hintText: hintText,
      emptyText: emptyText,
      keys: keys,
      theme: theme,
    );
  }
}
