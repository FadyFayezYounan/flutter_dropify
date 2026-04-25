import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'dropify_controller.dart';
import 'dropify_field.dart';
import 'dropify_keys.dart';
import 'dropify_source.dart';
import 'dropify_theme.dart';

/// A searchable, async, single-select Dropify dropdown.
class DropifyAsyncDropdown<T> extends StatelessWidget {
  /// Creates an async single-select dropdown.
  const DropifyAsyncDropdown({
    super.key,
    required this.loader,
    required this.value,
    required this.onChanged,
    this.controller,
    this.onError,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.enabled = true,
    this.hintText,
    this.emptyText,
    this.keys = DropifyKeys.defaultKeys,
    this.theme,
  });

  /// Loads items for the current query.
  final DropifyAsyncItemsLoader<T> loader;

  /// Controlled selected value.
  final T? value;

  /// Called when the selected value changes.
  final ValueChanged<T?> onChanged;

  /// Optional controller for open, close, clear, refresh, and retry commands.
  final DropifyController? controller;

  /// Called when [loader] throws.
  final DropifyErrorCallback? onError;

  /// Delay applied before search reloads.
  final Duration debounceDuration;

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
    properties.add(
      ObjectFlagProperty<DropifyAsyncItemsLoader<T>>.has('loader', loader),
    );
    properties.add(DiagnosticsProperty<T?>('value', value, defaultValue: null));
    properties.add(
      ObjectFlagProperty<ValueChanged<T?>>.has('onChanged', onChanged),
    );
    properties.add(
      DiagnosticsProperty<DropifyController?>('controller', controller),
    );
    properties.add(
      ObjectFlagProperty<DropifyErrorCallback?>.has('onError', onError),
    );
    properties.add(
      DiagnosticsProperty<Duration>('debounceDuration', debounceDuration),
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
      source: DropifySource<T>.async(
        loader: loader,
        debounceDuration: debounceDuration,
      ),
      value: value,
      onChanged: onChanged,
      controller: controller,
      onError: onError,
      enabled: enabled,
      hintText: hintText,
      emptyText: emptyText,
      keys: keys,
      theme: theme,
    );
  }
}
