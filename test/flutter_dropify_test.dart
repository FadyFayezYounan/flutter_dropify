import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dropify/flutter_dropify.dart';

void main() {
  test('static source filters labels and preserves disabled items', () {
    final items = <DropifyItem<String>>[
      const DropifyItem(value: 'ca', label: 'Canada'),
      const DropifyItem(value: 'cm', label: 'Cameroon', enabled: false),
      const DropifyItem(value: 'jp', label: 'Japan'),
    ];
    final source = DropifySource<String>.static(items: items);

    final results = source.filter(const DropifyQuery('cam'));

    expect(results, <DropifyItem<String>>[items[1]]);
    expect(results.single.enabled, isFalse);
    expect(
      const DropifyItem(value: 'ca', label: 'Canada'),
      const DropifyItem(value: 'ca', label: 'Canada'),
    );
  });

  test('paginated source requires a next page key when more pages exist', () {
    expect(
      () => DropifyPageResult<String>(
        items: const <DropifyItem<String>>[],
        hasMore: true,
      ),
      throwsAssertionError,
    );

    final source = DropifySource<String>.paginated(
      pageLoader: (request) async {
        expect(request.query.text, 'ca');
        expect(request.pageKey, 1);
        return const DropifyPageResult<String>(
          items: <DropifyItem<String>>[
            DropifyItem<String>(value: 'ca', label: 'Canada'),
          ],
          hasMore: false,
        );
      },
    );

    expect(source.isPaginated, isTrue);
    expect(source.isRemote, isTrue);
    expect(
      source.loadPage(
        const DropifyPageRequest(query: DropifyQuery('ca'), pageKey: 1),
      ),
      completion(
        isA<DropifyPageResult<String>>().having(
          (result) => result.items.single.label,
          'label',
          'Canada',
        ),
      ),
    );
  });

  testWidgets('opens, searches, selects, and closes once', (tester) async {
    String? selectedValue;
    var changes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyDropdown<String>(
            items: const <DropifyItem<String>>[
              DropifyItem(value: 'ca', label: 'Canada'),
              DropifyItem(value: 'jp', label: 'Japan'),
            ],
            value: selectedValue,
            onChanged: (value) {
              selectedValue = value;
              changes += 1;
            },
            hintText: 'Country',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.field));
    await tester.pumpAndSettle();

    expect(find.byKey(DropifyKeys.defaultKeys.menu), findsOneWidget);
    expect(find.byKey(DropifyKeys.defaultKeys.searchInput), findsOneWidget);

    await tester.enterText(
      find.byKey(DropifyKeys.defaultKeys.searchInput),
      'jap',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(DropifyKeys.defaultKeys.item('ca')), findsNothing);
    expect(find.byKey(DropifyKeys.defaultKeys.item('jp')), findsOneWidget);

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.item('jp')));
    await tester.pumpAndSettle();

    expect(selectedValue, 'jp');
    expect(changes, 1);
    expect(find.byKey(DropifyKeys.defaultKeys.menu), findsNothing);
  });

  testWidgets('shows empty state for no results', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyDropdown<String>(
            items: const <DropifyItem<String>>[
              DropifyItem(value: 'ca', label: 'Canada'),
            ],
            value: null,
            onChanged: (_) {},
            emptyText: 'Nothing matched',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.field));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(DropifyKeys.defaultKeys.searchInput),
      'zz',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(DropifyKeys.defaultKeys.emptyRow), findsOneWidget);
    expect(find.text('Nothing matched'), findsOneWidget);
  });

  testWidgets('disabled dropdown never opens or calls onChanged', (
    tester,
  ) async {
    var changes = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyDropdown<String>(
            items: const <DropifyItem<String>>[
              DropifyItem(value: 'ca', label: 'Canada'),
            ],
            value: null,
            onChanged: (_) {
              changes += 1;
            },
            enabled: false,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.field));
    await tester.pumpAndSettle();

    expect(find.byKey(DropifyKeys.defaultKeys.menu), findsNothing);
    expect(changes, 0);
  });

  testWidgets('async dropdown shows loading then loader items', (tester) async {
    final completer = Completer<List<DropifyItem<String>>>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyAsyncDropdown<String>(
            value: null,
            onChanged: (_) {},
            loader: (_) => completer.future,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.field));
    await tester.pump();

    expect(find.byKey(DropifyKeys.defaultKeys.loadingRow), findsOneWidget);

    completer.complete(const <DropifyItem<String>>[
      DropifyItem(value: 'ca', label: 'Canada'),
    ]);
    await tester.pumpAndSettle();

    expect(find.byKey(DropifyKeys.defaultKeys.loadingRow), findsNothing);
    expect(find.byKey(DropifyKeys.defaultKeys.item('ca')), findsOneWidget);
  });

  testWidgets('async error calls onError and retry reloads same query', (
    tester,
  ) async {
    final firstLoad = Completer<List<DropifyItem<String>>>();
    final retryLoad = Completer<List<DropifyItem<String>>>();
    final queries = <String>[];
    String? selectedValue;
    var errors = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyAsyncDropdown<String>(
            value: null,
            onChanged: (value) {
              selectedValue = value;
            },
            loader: (query) {
              queries.add(query.text);
              return queries.length == 1 ? firstLoad.future : retryLoad.future;
            },
            onError: (_, _) {
              errors += 1;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.field));
    await tester.pump();

    firstLoad.completeError(StateError('offline'));
    await tester.pump();

    expect(errors, 1);
    expect(find.byKey(DropifyKeys.defaultKeys.errorRow), findsOneWidget);
    expect(find.byKey(DropifyKeys.defaultKeys.retryButton), findsOneWidget);

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.retryButton));
    await tester.pump();

    retryLoad.complete(const <DropifyItem<String>>[
      DropifyItem(value: 'ca', label: 'Canada'),
    ]);
    await tester.pump();

    expect(queries, <String>['', '']);
    expect(find.byKey(DropifyKeys.defaultKeys.item('ca')), findsOneWidget);

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.item('ca')));
    await tester.pump();

    expect(selectedValue, 'ca');
  });

  testWidgets('async search ignores stale older completion', (tester) async {
    final loads = <String, Completer<List<DropifyItem<String>>>>{};

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyAsyncDropdown<String>(
            value: null,
            onChanged: (_) {},
            debounceDuration: Duration.zero,
            loader: (query) {
              final completer = Completer<List<DropifyItem<String>>>();
              loads[query.text] = completer;
              return completer.future;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.field));
    await tester.pump();
    await tester.enterText(
      find.byKey(DropifyKeys.defaultKeys.searchInput),
      'ca',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(DropifyKeys.defaultKeys.searchInput),
      'jap',
    );
    await tester.pump();

    loads['jap']!.complete(const <DropifyItem<String>>[
      DropifyItem(value: 'jp', label: 'Japan'),
    ]);
    await tester.pump();

    loads['ca']!.complete(const <DropifyItem<String>>[
      DropifyItem(value: 'ca', label: 'Canada'),
    ]);
    await tester.pump();

    expect(find.byKey(DropifyKeys.defaultKeys.item('jp')), findsOneWidget);
    expect(find.byKey(DropifyKeys.defaultKeys.item('ca')), findsNothing);
  });

  testWidgets('controller opens clears search and refreshes async source', (
    tester,
  ) async {
    final controller = DropifyController();
    final queries = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyAsyncDropdown<String>(
            controller: controller,
            value: null,
            onChanged: (_) {},
            debounceDuration: Duration.zero,
            loader: (query) async {
              queries.add(query.text);
              return <DropifyItem<String>>[
                DropifyItem(value: query.text, label: 'Result ${query.text}'),
              ];
            },
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    await tester.enterText(
      find.byKey(DropifyKeys.defaultKeys.searchInput),
      'ca',
    );
    await tester.pump();

    controller.clearSearch();
    await tester.pump();
    controller.refresh();
    await tester.pump();

    expect(queries, contains('ca'));
    expect(queries.last, '');
    expect(find.byKey(DropifyKeys.defaultKeys.searchInput), findsOneWidget);
  });

  testWidgets('paginated dropdown loads first page and next page once', (
    tester,
  ) async {
    final requests = <DropifyPageRequest>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyPaginatedDropdown<int>(
            value: null,
            onChanged: (_) {},
            pageLoader: (request) async {
              requests.add(request);
              final pageNumber = request.pageKey as int? ?? 0;
              return DropifyPageResult<int>(
                items: List<DropifyItem<int>>.generate(
                  12,
                  (index) => DropifyItem<int>(
                    value: pageNumber * 12 + index,
                    label: 'Item ${pageNumber * 12 + index}',
                  ),
                ),
                hasMore: pageNumber == 0,
                nextPageKey: pageNumber == 0 ? 1 : null,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.field));
    await tester.pumpAndSettle();

    expect(requests.map((request) => request.pageKey), <Object?>[null]);

    await tester.drag(
      find.byKey(DropifyKeys.defaultKeys.menu),
      const Offset(0.0, -500.0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(DropifyKeys.defaultKeys.menu),
      const Offset(0.0, -500.0),
    );
    await tester.pumpAndSettle();

    expect(requests.map((request) => request.pageKey), <Object?>[null, 1]);
    await tester.scrollUntilVisible(
      find.byKey(DropifyKeys.defaultKeys.item(23)),
      200.0,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(DropifyKeys.defaultKeys.item(23)), findsOneWidget);
  });

  testWidgets('paginated next-page error preserves items and retries page', (
    tester,
  ) async {
    final failingPage = Completer<DropifyPageResult<int>>();
    final retryPage = Completer<DropifyPageResult<int>>();
    final requests = <DropifyPageRequest>[];
    var pageOneAttempts = 0;
    var errors = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyPaginatedDropdown<int>(
            value: null,
            onChanged: (_) {},
            onError: (_, _) {
              errors += 1;
            },
            pageLoader: (request) {
              requests.add(request);
              if (request.pageKey == null) {
                return Future<DropifyPageResult<int>>.value(
                  DropifyPageResult<int>(
                    items: List<DropifyItem<int>>.generate(
                      12,
                      (index) =>
                          DropifyItem<int>(value: index, label: 'Item $index'),
                    ),
                    hasMore: true,
                    nextPageKey: 1,
                  ),
                );
              }
              pageOneAttempts += 1;
              return pageOneAttempts == 1
                  ? failingPage.future
                  : retryPage.future;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.field));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(DropifyKeys.defaultKeys.menu),
      const Offset(0.0, -500.0),
    );
    await tester.pump();

    failingPage.completeError(StateError('page failed'));
    await tester.pumpAndSettle();

    expect(errors, 1);
    expect(find.byKey(DropifyKeys.defaultKeys.item(11)), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(DropifyKeys.defaultKeys.paginationErrorRow),
      100.0,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(DropifyKeys.defaultKeys.paginationErrorRow),
      findsOneWidget,
    );
    expect(
      find.byKey(DropifyKeys.defaultKeys.paginationRetryButton),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.paginationRetryButton));
    await tester.pump();

    retryPage.complete(
      DropifyPageResult<int>(
        items: List<DropifyItem<int>>.generate(
          2,
          (index) =>
              DropifyItem<int>(value: 12 + index, label: 'Item ${12 + index}'),
        ),
        hasMore: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(requests.map((request) => request.pageKey), <Object?>[null, 1, 1]);
    expect(
      find.byKey(DropifyKeys.defaultKeys.paginationErrorRow),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.byKey(DropifyKeys.defaultKeys.item(13)),
      100.0,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(DropifyKeys.defaultKeys.item(13)), findsOneWidget);
  });

  testWidgets('paginated search resets pages and ignores stale completions', (
    tester,
  ) async {
    final oldNextPage = Completer<DropifyPageResult<String>>();
    final searchPage = Completer<DropifyPageResult<String>>();
    final requests = <({String query, Object? pageKey})>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DropifyPaginatedDropdown<String>(
            value: null,
            onChanged: (_) {},
            debounceDuration: Duration.zero,
            pageLoader: (request) {
              requests.add((
                query: request.query.text,
                pageKey: request.pageKey,
              ));
              if (request.query.text == 'jap') {
                return searchPage.future;
              }
              if (request.pageKey == 1) {
                return oldNextPage.future;
              }
              return Future<DropifyPageResult<String>>.value(
                DropifyPageResult<String>(
                  items: List<DropifyItem<String>>.generate(
                    12,
                    (index) => DropifyItem<String>(
                      value: 'old-$index',
                      label: 'Old $index',
                    ),
                  ),
                  hasMore: true,
                  nextPageKey: 1,
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(DropifyKeys.defaultKeys.field));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(DropifyKeys.defaultKeys.menu),
      const Offset(0.0, -500.0),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(DropifyKeys.defaultKeys.searchInput),
      'jap',
    );
    await tester.pump();

    searchPage.complete(
      const DropifyPageResult<String>(
        items: <DropifyItem<String>>[
          DropifyItem<String>(value: 'jp', label: 'Japan'),
        ],
        hasMore: false,
      ),
    );
    await tester.pumpAndSettle();

    oldNextPage.complete(
      const DropifyPageResult<String>(
        items: <DropifyItem<String>>[
          DropifyItem<String>(value: 'old-stale', label: 'Old stale'),
        ],
        hasMore: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(requests, <({String query, Object? pageKey})>[
      (query: '', pageKey: null),
      (query: '', pageKey: 1),
      (query: 'jap', pageKey: null),
    ]);
    expect(find.byKey(DropifyKeys.defaultKeys.item('jp')), findsOneWidget);
    expect(find.byKey(DropifyKeys.defaultKeys.item('old-stale')), findsNothing);
    expect(find.byKey(DropifyKeys.defaultKeys.item('old-11')), findsNothing);
  });
}
