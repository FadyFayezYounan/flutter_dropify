import 'dropify_item.dart';

/// Describes the current dropdown search query.
class DropifyQuery {
  /// Creates a query with raw [text].
  const DropifyQuery(this.text);

  /// The current search text.
  final String text;

  /// The query text trimmed and lowercased for default matching.
  String get normalizedText => text.trim().toLowerCase();
}

/// Signature for static local item filtering.
typedef DropifyItemFilter<T> =
    bool Function(DropifyItem<T> item, DropifyQuery query);

/// A local static source of typed Dropify items.
class DropifySource<T> {
  /// Creates a static local item source.
  const DropifySource.static({
    required List<DropifyItem<T>> items,
    DropifyItemFilter<T>? filter,
  }) : _items = items,
       _filter = filter;

  final List<DropifyItem<T>> _items;
  final DropifyItemFilter<T>? _filter;

  /// All source items in their original order.
  List<DropifyItem<T>> get items => List<DropifyItem<T>>.unmodifiable(_items);

  /// Returns items matching [query] using the custom filter or label contains.
  List<DropifyItem<T>> filter(DropifyQuery query) {
    final normalizedText = query.normalizedText;
    if (normalizedText.isEmpty) {
      return items;
    }

    final itemFilter = _filter;
    return _items
        .where((item) {
          if (itemFilter != null) {
            return itemFilter(item, query);
          }
          return item.label.toLowerCase().contains(normalizedText);
        })
        .toList(growable: false);
  }
}
