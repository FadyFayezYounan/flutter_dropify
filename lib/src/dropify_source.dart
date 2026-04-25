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

/// Loads a page of items for a paginated Dropify source.
typedef DropifyPageLoader<T> =
    Future<DropifyPageResult<T>> Function(DropifyPageRequest request);

/// Describes one paginated source request.
class DropifyPageRequest {
  /// Creates a page request for [query] and optional [pageKey].
  const DropifyPageRequest({required this.query, this.pageKey});

  /// The current search query.
  final DropifyQuery query;

  /// The source-owned key for the page to load, or null for the first page.
  final Object? pageKey;
}

/// Describes one loaded page of Dropify items.
class DropifyPageResult<T> {
  /// Creates a page result.
  const DropifyPageResult({
    required this.items,
    required this.hasMore,
    this.nextPageKey,
  }) : assert(
         !hasMore || nextPageKey != null,
         'nextPageKey must be provided when hasMore is true.',
       );

  /// Items returned for the requested page.
  final List<DropifyItem<T>> items;

  /// Whether another page can be requested.
  final bool hasMore;

  /// The key to send with the next [DropifyPageRequest].
  final Object? nextPageKey;
}

enum _DropifySourceKind { static, async, paginated }

/// A source of typed Dropify items.
class DropifySource<T> {
  /// Creates a static local item source.
  const DropifySource.static({
    required List<DropifyItem<T>> items,
    DropifyItemFilter<T>? filter,
  }) : _items = items,
       _filter = filter,
       _loader = null,
       _pageLoader = null,
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
       _pageLoader = null,
       _debounceDuration = debounceDuration,
       _kind = _DropifySourceKind.async;

  /// Creates a paginated async item source.
  DropifySource.paginated({
    required DropifyPageLoader<T> pageLoader,
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) : assert(!debounceDuration.isNegative, 'debounceDuration must be >= 0'),
       _items = const <DropifyItem<Never>>[],
       _filter = null,
       _loader = null,
       _pageLoader = pageLoader,
       _debounceDuration = debounceDuration,
       _kind = _DropifySourceKind.paginated;

  final List<DropifyItem<T>> _items;
  final DropifyItemFilter<T>? _filter;
  final DropifyAsyncItemsLoader<T>? _loader;
  final DropifyPageLoader<T>? _pageLoader;
  final Duration _debounceDuration;
  final _DropifySourceKind _kind;

  /// Whether this source loads items asynchronously.
  bool get isAsync => _kind == _DropifySourceKind.async;

  /// Whether this source loads items one page at a time.
  bool get isPaginated => _kind == _DropifySourceKind.paginated;

  /// Whether this source loads data from callbacks instead of local filtering.
  bool get isRemote => isAsync || isPaginated;

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

  /// Loads one page of items for [request] from a paginated source.
  Future<DropifyPageResult<T>> loadPage(DropifyPageRequest request) {
    final pageLoader = _pageLoader;
    assert(
      pageLoader != null,
      'Only paginated Dropify sources can load pages.',
    );
    return pageLoader!(request);
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
