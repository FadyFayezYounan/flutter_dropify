import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dropify_item.dart';
import 'dropify_pagination.dart';
import 'dropify_query.dart';

/// Filters a static [item] for a [query].
typedef DropifyFilter<T> =
    bool Function(DropifyItem<T> item, DropifyQuery query);

/// Loads async Dropify items for a [query].
typedef DropifyAsyncLoader<T> =
    FutureOr<List<DropifyItem<T>>> Function(DropifyQuery query);

/// Loads a page of Dropify items for a request.
typedef DropifyPaginatedLoader<T, PageKey> =
    FutureOr<DropifyPageResult<T, PageKey>> Function(
      DropifyPageRequest<PageKey> request,
    );

/// Internal page-loader shape used after erasing public page-key typing.
typedef DropifyPageLoader<T> =
    FutureOr<DropifyPageResult<T, Object?>> Function(
      DropifyPageRequest<Object?> request,
    );

/// Provides static Dropify items.
@immutable
class DropifySource<T> {
  /// Creates a static [DropifySource].
  const DropifySource.static({required this.items, this.filter})
    : asyncLoader = null,
      paginatedLoader = null,
      firstPageKey = null;

  /// Creates an async [DropifySource].
  const DropifySource.async({required DropifyAsyncLoader<T> loader})
    : items = const [],
      filter = null,
      asyncLoader = loader,
      paginatedLoader = null,
      firstPageKey = null;

  const DropifySource._paginated({
    required this.paginatedLoader,
    required this.firstPageKey,
  }) : items = const [],
       filter = null,
       asyncLoader = null;

  /// Creates a paginated [DropifySource].
  factory DropifySource.paginated({
    required DropifyPaginatedLoader<T, Object?> loader,
    Object? firstPageKey,
  }) {
    Future<DropifyPageResult<T, Object?>>? pendingFuture;
    DropifyPageRequest<Object?>? pendingRequest;
    return DropifySource<T>._paginated(
      firstPageKey: firstPageKey,
      paginatedLoader: (request) {
        final currentPendingFuture = pendingFuture;
        final currentPendingRequest = pendingRequest;
        if (currentPendingFuture != null &&
            currentPendingRequest?.query == request.query &&
            currentPendingRequest?.pageKey == request.pageKey) {
          return currentPendingFuture;
        }
        late final Future<DropifyPageResult<T, Object?>> future;
        future =
            Future<DropifyPageResult<T, Object?>>.sync(
              () => loader(request),
            ).whenComplete(() {
              if (identical(pendingFuture, future)) {
                pendingFuture = null;
                pendingRequest = null;
              }
            });
        pendingFuture = future;
        pendingRequest = request;
        return future;
      },
    );
  }

  /// Items available to the dropdown.
  final List<DropifyItem<T>> items;

  /// Optional custom filter callback.
  final DropifyFilter<T>? filter;

  /// Optional async item loader.
  final DropifyAsyncLoader<T>? asyncLoader;

  /// Optional paginated item loader.
  final DropifyPageLoader<T>? paginatedLoader;

  /// First page key for paginated sources.
  final Object? firstPageKey;

  /// Whether this source loads items asynchronously.
  bool get isAsync => asyncLoader != null;

  /// Whether this source loads paginated items.
  bool get isPaginated => paginatedLoader != null;

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
