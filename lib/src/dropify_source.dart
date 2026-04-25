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

/// Loads items for an async Dropify source.
typedef DropifyAsyncItemsLoader<T> =
    Future<List<DropifyItem<T>>> Function(DropifyQuery query);

/// Reports an async loading failure.
typedef DropifyErrorCallback =
    void Function(Object error, StackTrace stackTrace);

enum _DropifySourceKind { static, async }

/// A source of typed Dropify items.
class DropifySource<T> {
  /// Creates a static local item source.
  const DropifySource.static({
    required List<DropifyItem<T>> items,
    DropifyItemFilter<T>? filter,
  }) : _items = items,
       _filter = filter,
       _loader = null,
       _debounceDuration = Duration.zero,
       _kind = _DropifySourceKind.static;

  /// Creates an async item source.
  DropifySource.async({
    required DropifyAsyncItemsLoader<T> loader,
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) : assert(!debounceDuration.isNegative, 'debounceDuration must be >= 0'),
       _items = const <DropifyItem<Never>>[],
       _filter = null,
       _loader = loader,
       _debounceDuration = debounceDuration,
       _kind = _DropifySourceKind.async;

  final List<DropifyItem<T>> _items;
  final DropifyItemFilter<T>? _filter;
  final DropifyAsyncItemsLoader<T>? _loader;
  final Duration _debounceDuration;
  final _DropifySourceKind _kind;

  /// Whether this source loads items asynchronously.
  bool get isAsync => _kind == _DropifySourceKind.async;

  /// Delay applied before async search reloads.
  Duration get debounceDuration => _debounceDuration;

  /// All source items in their original order.
  List<DropifyItem<T>> get items => List<DropifyItem<T>>.unmodifiable(_items);

  /// Loads items for [query] from an async source.
  Future<List<DropifyItem<T>>> load(DropifyQuery query) {
    final loader = _loader;
    assert(loader != null, 'Only async Dropify sources can load items.');
    return loader!(query);
  }

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
