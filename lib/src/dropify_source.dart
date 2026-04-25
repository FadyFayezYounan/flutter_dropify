import 'package:flutter/foundation.dart';

import 'dropify_item.dart';
import 'dropify_query.dart';

/// Filters a static [item] for a [query].
typedef DropifyFilter<T> =
    bool Function(DropifyItem<T> item, DropifyQuery query);

/// Provides static Dropify items.
@immutable
class DropifySource<T> {
  /// Creates a static [DropifySource].
  const DropifySource.static({required this.items, this.filter});

  /// Items available to the dropdown.
  final List<DropifyItem<T>> items;

  /// Optional custom filter callback.
  final DropifyFilter<T>? filter;

  /// Resolves visible items for [query].
  List<DropifyItem<T>> resolve(DropifyQuery query) {
    if (query.isEmpty) {
      return List<DropifyItem<T>>.unmodifiable(items);
    }

    final matches = filter ?? _defaultFilter;
    return List<DropifyItem<T>>.unmodifiable(
      items.where((item) => matches(item, query)),
    );
  }
}

bool _defaultFilter<T>(DropifyItem<T> item, DropifyQuery query) {
  return item.label.toLowerCase().contains(query.normalizedText);
}
