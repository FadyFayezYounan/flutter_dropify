import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'dropify_controller.dart';
import 'dropify_field.dart';
import 'dropify_keys.dart';
import 'dropify_source.dart';
import 'dropify_theme.dart';

/// A searchable, paginated, single-select Dropify dropdown.
class DropifyPaginatedDropdown<T> extends StatelessWidget {
  /// Creates a paginated single-select dropdown.
  const DropifyPaginatedDropdown({
    super.key,
    required this.pageLoader,
    required this.value,
    required this.onChanged,
    this.controller,
    this.onError,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.paginationTriggerExtent = 80.0,
    this.enabled = true,
    this.hintText,
    this.emptyText,
    this.keys = DropifyKeys.defaultKeys,
    this.theme,
  });

  /// Loads one page for the current query.
  final DropifyPageLoader<T> pageLoader;

  /// Controlled selected value.
  final T? value;

  /// Called when the selected value changes.
  final ValueChanged<T?> onChanged;

  /// Optional controller for open, close, clear, refresh, and retry commands.
  final DropifyController? controller;

  /// Called when [pageLoader] throws.
  final DropifyErrorCallback? onError;

  /// Delay applied before search reloads the first page.
  final Duration debounceDuration;

  /// Remaining scroll extent that triggers the next page load.
  final double paginationTriggerExtent;

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
      ObjectFlagProperty<DropifyPageLoader<T>>.has('pageLoader', pageLoader),
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
      DoubleProperty('paginationTriggerExtent', paginationTriggerExtent),
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
      source: DropifySource<T>.paginated(
        pageLoader: pageLoader,
        debounceDuration: debounceDuration,
      ),
      value: value,
      onChanged: onChanged,
      controller: controller,
      onError: onError,
      enabled: enabled,
      hintText: hintText,
      emptyText: emptyText,
      paginationTriggerExtent: paginationTriggerExtent,
      keys: keys,
      theme: theme,
    );
  }
}
