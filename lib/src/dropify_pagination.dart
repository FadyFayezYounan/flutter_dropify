import 'package:flutter/foundation.dart';

import 'dropify_item.dart';
import 'dropify_query.dart';

/// Describes a paginated data request for Dropify widgets.
@immutable
class DropifyPageRequest<PageKey> {
  /// Creates a [DropifyPageRequest].
  const DropifyPageRequest({required this.query, required this.pageKey});

  /// The search query for this page request.
  final DropifyQuery query;

  /// The key identifying the page to load.
  final PageKey? pageKey;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DropifyPageRequest<PageKey> &&
            other.query == query &&
            other.pageKey == pageKey;
  }

  @override
  int get hashCode => Object.hash(query, pageKey);

  @override
  String toString() {
    return 'DropifyPageRequest<$PageKey>(query: $query, pageKey: $pageKey)';
  }
}

/// Result returned by paginated Dropify loaders.
@immutable
class DropifyPageResult<T, PageKey> {
  /// Creates a [DropifyPageResult].
  const DropifyPageResult({
    required this.items,
    required this.nextPageKey,
    required this.hasMore,
  }) : assert(
         !hasMore || nextPageKey != null,
         'DropifyPageResult with hasMore true must provide nextPageKey.',
       );

  /// Items loaded for the requested page.
  final List<DropifyItem<T>> items;

  /// Key for the next page, when [hasMore] is true.
  final PageKey? nextPageKey;

  /// Whether another page can be loaded after this result.
  final bool hasMore;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DropifyPageResult<T, PageKey> &&
            listEquals(other.items, items) &&
            other.nextPageKey == nextPageKey &&
            other.hasMore == hasMore;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), nextPageKey, hasMore);

  @override
  String toString() {
    return 'DropifyPageResult<$T, $PageKey>(items: $items, nextPageKey: $nextPageKey, hasMore: $hasMore)';
  }
}
