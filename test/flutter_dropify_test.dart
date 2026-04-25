import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dropify/flutter_dropify.dart';

void main() {
  const items = <DropifyItem<String>>[
    DropifyItem(value: 'eg', label: 'Egypt'),
    DropifyItem(value: 'fr', label: 'France'),
    DropifyItem(value: 'de', label: 'Germany', enabled: false),
    DropifyItem(value: 'jp', label: 'Japan'),
  ];

  test('DropifyQuery normalizes raw search text', () {
    final query = DropifyQuery.fromRaw('  Fra  ');

    expect(query.rawText, '  Fra  ');
    expect(query.normalizedText, 'fra');
  });

  test('DropifyItem uses explicit identity before value fallback', () {
    const explicit = DropifyItem(value: 'eg', label: 'Egypt', id: 'country-eg');
    const fallback = DropifyItem(value: 'fr', label: 'France');

    expect(explicit.identity, 'country-eg');
    expect(fallback.identity, 'fr');
  });

  test('DropifyPageResult asserts when a continuing page has no next key', () {
    expect(
      () => DropifyPageResult<String, int>(
        items: const <DropifyItem<String>>[],
        nextPageKey: null,
        hasMore: true,
      ),
      throwsAssertionError,
    );
  });

  testWidgets(
    'static single opens, filters, selects enabled item, calls onChanged, closes',
    (tester) async {
      String? changed;
      await tester.pumpWidget(
        _Harness(
          child: DropifyDropdown<String>(
            value: null,
            items: items,
            onChanged: (value) => changed = value,
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      await robot.search('fra');
      expect(find.text('France'), findsOneWidget);
      expect(find.text('Egypt'), findsNothing);

      await robot.selectItem('fr');

      expect(changed, 'fr');
      expect(find.byKey(DropifyKeys.menuOverlay), findsNothing);
    },
  );

  testWidgets(
    'static multi toggles immutable values, clears, selects visible, and stays open',
    (tester) async {
      final emitted = <List<String>>[];
      var values = <String>[];
      await tester.pumpWidget(
        _Harness(
          child: StatefulBuilder(
            builder: (context, setState) {
              return DropifyDropdown<String>.multi(
                values: values,
                items: items,
                onChanged: (nextValues) {
                  emitted.add(nextValues);
                  setState(() => values = nextValues);
                },
              );
            },
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      await robot.selectItem('eg');
      await robot.selectItem('fr');
      await robot.selectItem('eg');

      expect(emitted.map((values) => values.toList()), <List<String>>[
        <String>['eg'],
        <String>['eg', 'fr'],
        <String>['fr'],
      ]);
      expect(() => emitted.last.add('jp'), throwsUnsupportedError);
      expect(find.byKey(DropifyKeys.menuOverlay), findsOneWidget);

      await robot.clearAll();
      expect(values, isEmpty);

      await robot.search('jap');
      await robot.selectVisible();
      expect(values, <String>['jp']);
      expect(find.byKey(DropifyKeys.menuOverlay), findsOneWidget);
    },
  );

  testWidgets(
    'empty/search-empty, disabled widget and row, custom filter, duplicate visible identity assert',
    (tester) async {
      String? changed;
      await tester.pumpWidget(
        _Harness(
          child: DropifyDropdown<String>(
            value: null,
            items: items,
            onChanged: (value) => changed = value,
            filter: (item, query) => item.label.startsWith(query.rawText),
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      await robot.search('E');
      expect(find.text('Egypt'), findsOneWidget);
      expect(find.text('France'), findsNothing);

      await robot.search('Nope');
      expect(find.byKey(DropifyKeys.emptyRow), findsOneWidget);

      await robot.search('G');
      await robot.selectItem('de');
      expect(changed, isNull);
      expect(find.byKey(DropifyKeys.menuOverlay), findsOneWidget);

      await tester.pumpWidget(
        _Harness(
          child: DropifyDropdown<String>(
            value: null,
            items: items,
            onChanged: null,
          ),
        ),
      );
      await robot.open();
      expect(find.byKey(DropifyKeys.menuOverlay), findsNothing);

      await tester.pumpWidget(
        _Harness(
          child: DropifyDropdown<String>(
            value: null,
            items: const <DropifyItem<String>>[
              DropifyItem(value: 'eg', label: 'Egypt', id: 'duplicate'),
              DropifyItem(value: 'fr', label: 'France', id: 'duplicate'),
            ],
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.byKey(DropifyKeys.field));
      await tester.pump();
      expect(tester.takeException(), isFlutterError);
    },
  );

  testWidgets('builder callbacks receive state without losing stable keys', (
    tester,
  ) async {
    final fieldStates = <DropifyFieldState<String>>[];
    final searchStates = <DropifySearchState>[];
    final itemStates = <DropifyItemState<String>>[];
    await tester.pumpWidget(
      _Harness(
        child: DropifyDropdown<String>(
          value: 'eg',
          items: items,
          onChanged: (_) {},
          fieldBuilder: (context, state) {
            fieldStates.add(state);
            return Text(
              state.isOpen ? 'Open custom field' : 'Closed custom field',
            );
          },
          searchBuilder: (context, state) {
            searchStates.add(state);
            return TextField(
              controller: state.controller,
              focusNode: state.focusNode,
              onChanged: (_) {},
            );
          },
          itemBuilder: (context, state) {
            itemStates.add(state);
            return Text(
              '${state.item.label}:${state.isSelected}:${state.isDisabled}:${state.isHighlighted}',
            );
          },
          menuHeaderBuilder: (context) => const Text('Header'),
          menuFooterBuilder: (context) => const Text('Footer'),
        ),
      ),
    );
    final robot = _DropifyRobot(tester);

    expect(find.byKey(DropifyKeys.field), findsOneWidget);
    await robot.open();

    expect(find.byKey(DropifyKeys.searchInput), findsOneWidget);
    expect(find.byKey(DropifyKeys.itemRow('eg')), findsOneWidget);
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Footer'), findsOneWidget);
    expect(fieldStates.last.isOpen, isTrue);
    expect(searchStates.last.query, DropifyQuery.fromRaw(''));
    expect(
      itemStates.any((state) => state.item.value == 'eg' && state.isSelected),
      isTrue,
    );
    expect(
      itemStates.any((state) => state.item.value == 'de' && state.isDisabled),
      isTrue,
    );
    expect(itemStates.every((state) => !state.isHighlighted), isTrue);
  });

  testWidgets(
    'async first open shows loading, renders latest loaded items, selects enabled item',
    (tester) async {
      final completer = Completer<List<DropifyItem<String>>>();
      String? changed;
      await tester.pumpWidget(
        _Harness(
          child: DropifyAsyncDropdown<String>(
            value: null,
            loader: (_) => completer.future,
            onChanged: (value) => changed = value,
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      expect(find.byKey(DropifyKeys.loadingRow), findsOneWidget);

      completer.complete(items);
      await tester.pumpAndSettle();
      expect(find.byKey(DropifyKeys.loadingRow), findsNothing);
      expect(find.text('France'), findsOneWidget);

      await robot.selectItem('fr');
      expect(changed, 'fr');
      expect(find.byKey(DropifyKeys.menuOverlay), findsNothing);
    },
  );

  testWidgets(
    'async first-load error shows error UI, calls onError, retry succeeds, menu stays open',
    (tester) async {
      final firstLoad = Completer<List<DropifyItem<String>>>();
      final retryLoad = Completer<List<DropifyItem<String>>>();
      final loads = <Completer<List<DropifyItem<String>>>>[
        firstLoad,
        retryLoad,
      ];
      Object? reportedError;
      await tester.pumpWidget(
        _Harness(
          child: DropifyAsyncDropdown<String>(
            value: null,
            loader: (_) => loads.removeAt(0).future,
            onChanged: (_) {},
            onError: (error, _) => reportedError = error,
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      expect(find.byKey(DropifyKeys.loadingRow), findsOneWidget);
      final error = StateError('network failed');
      firstLoad.completeError(error, StackTrace.current);
      await tester.pump();
      await tester.pump();

      expect(find.byKey(DropifyKeys.errorRow), findsOneWidget);
      expect(find.byKey(DropifyKeys.menuOverlay), findsOneWidget);
      expect(reportedError, same(error));

      await robot.retry();
      expect(find.byKey(DropifyKeys.loadingRow), findsOneWidget);
      retryLoad.complete(items);
      await tester.pumpAndSettle();

      expect(find.byKey(DropifyKeys.errorRow), findsNothing);
      expect(find.text('Egypt'), findsOneWidget);
      expect(find.byKey(DropifyKeys.menuOverlay), findsOneWidget);
    },
  );

  testWidgets(
    'async debounced search reloads query, ignores stale completions, and treats sync throws as loader errors',
    (tester) async {
      final requests = <String, Completer<List<DropifyItem<String>>>>{};
      final queries = <String>[];
      Object? reportedError;
      await tester.pumpWidget(
        _Harness(
          child: DropifyAsyncDropdown<String>(
            value: null,
            loader: (query) {
              queries.add(query.normalizedText);
              if (query.normalizedText == 'boom') {
                throw StateError('sync failed');
              }
              final completer = Completer<List<DropifyItem<String>>>();
              requests[query.normalizedText] = completer;
              return completer.future;
            },
            searchDebounceDuration: const Duration(milliseconds: 20),
            onChanged: (_) {},
            onError: (error, _) => reportedError = error,
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      requests['']!.complete(items);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(DropifyKeys.searchInput), 'fra');
      await tester.pump(const Duration(milliseconds: 10));
      expect(requests.containsKey('fra'), isFalse);
      await tester.pump(const Duration(milliseconds: 20));
      expect(requests.containsKey('fra'), isTrue);

      await tester.enterText(find.byKey(DropifyKeys.searchInput), 'jap');
      await tester.pump(const Duration(milliseconds: 20));
      requests['jap']!.complete(<DropifyItem<String>>[items.last]);
      await tester.pumpAndSettle();
      requests['fra']!.complete(<DropifyItem<String>>[items[1]]);
      await tester.pumpAndSettle();

      expect(queries, containsAllInOrder(<String>['', 'fra', 'jap']));
      expect(find.text('Japan'), findsOneWidget);
      expect(find.text('France'), findsNothing);

      await tester.enterText(find.byKey(DropifyKeys.searchInput), 'boom');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      expect(find.byKey(DropifyKeys.errorRow), findsOneWidget);
      expect(reportedError, isA<StateError>());
    },
  );

  testWidgets(
    'async multi selections persist across reload, search, error, and retry',
    (tester) async {
      final requests = <String, List<Completer<List<DropifyItem<String>>>>>{};
      final controller = DropifyController();
      var values = <String>[];
      await tester.pumpWidget(
        _Harness(
          child: StatefulBuilder(
            builder: (context, setState) {
              return DropifyAsyncDropdown<String>.multi(
                values: values,
                controller: controller,
                loader: (query) {
                  final completer = Completer<List<DropifyItem<String>>>();
                  requests
                      .putIfAbsent(
                        query.normalizedText,
                        () => <Completer<List<DropifyItem<String>>>>[],
                      )
                      .add(completer);
                  return completer.future;
                },
                searchDebounceDuration: const Duration(milliseconds: 10),
                onChanged: (nextValues) {
                  setState(() => values = nextValues);
                },
              );
            },
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      requests['']!.single.complete(items);
      await tester.pumpAndSettle();
      await robot.selectItem('eg');

      await tester.enterText(find.byKey(DropifyKeys.searchInput), 'jap');
      await tester.pump(const Duration(milliseconds: 10));
      requests['jap']!.single.complete(<DropifyItem<String>>[items.last]);
      await tester.pumpAndSettle();
      await robot.selectItem('jp');

      await tester.enterText(find.byKey(DropifyKeys.searchInput), 'err');
      await tester.pump(const Duration(milliseconds: 10));
      requests['err']!.first.completeError(
        StateError('failed'),
        StackTrace.current,
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(DropifyKeys.errorRow), findsOneWidget);
      expect(values, <String>['eg', 'jp']);

      controller.retry();
      await tester.pump();
      requests['err']!.last.complete(<DropifyItem<String>>[items[1]]);
      await tester.pumpAndSettle();

      expect(values, <String>['eg', 'jp']);
      expect(find.byKey(DropifyKeys.selectedChip('eg')), findsOneWidget);
      expect(find.byKey(DropifyKeys.selectedChip('jp')), findsOneWidget);
      expect(find.text('France'), findsOneWidget);
    },
  );

  testWidgets(
    'paginated first page loads on open, scroll loads next page once, and single select closes',
    (tester) async {
      final requests = <int?, Completer<DropifyPageResult<String, int>>>{};
      String? changed;
      await tester.pumpWidget(
        _Harness(
          alignment: Alignment.topCenter,
          child: DropifyPaginatedDropdown<String, int>(
            value: null,
            firstPageKey: 1,
            pageLoader: (request) {
              final completer = Completer<DropifyPageResult<String, int>>();
              requests[request.pageKey] = completer;
              return completer.future;
            },
            onChanged: (value) => changed = value,
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      expect(find.byKey(DropifyKeys.loadingRow), findsOneWidget);

      requests[1]!.complete(
        DropifyPageResult<String, int>(
          items: _pagedItems(start: 0, count: 30),
          nextPageKey: 2,
          hasMore: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(DropifyKeys.itemRow('p0')), findsOneWidget);
      expect(requests.containsKey(2), isFalse);

      await robot.scrollToItem('p29');
      await tester.pump();
      expect(requests.containsKey(2), isTrue);
      await tester.pump();
      expect(find.byKey(DropifyKeys.paginationLoadingRow), findsOneWidget);

      requests[2]!.complete(
        DropifyPageResult<String, int>(
          items: _pagedItems(start: 30, count: 3),
          nextPageKey: null,
          hasMore: false,
        ),
      );
      await tester.pumpAndSettle();
      await robot.scrollToItem('p30');
      await robot.selectItem('p30');

      expect(changed, 'p30');
      expect(find.byKey(DropifyKeys.menuOverlay), findsNothing);
    },
  );

  testWidgets(
    'paginated duplicate load-more is coalesced and next-page error retries failed page only',
    (tester) async {
      final requests =
          <int?, List<Completer<DropifyPageResult<String, int>>>>{};
      await tester.pumpWidget(
        _Harness(
          alignment: Alignment.topCenter,
          child: DropifyPaginatedDropdown<String, int>(
            value: null,
            firstPageKey: 1,
            pageLoader: (request) {
              final completer = Completer<DropifyPageResult<String, int>>();
              requests
                  .putIfAbsent(
                    request.pageKey,
                    () => <Completer<DropifyPageResult<String, int>>>[],
                  )
                  .add(completer);
              return completer.future;
            },
            onChanged: (_) {},
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      requests[1]!.single.complete(
        DropifyPageResult<String, int>(
          items: _pagedItems(start: 0, count: 30),
          nextPageKey: 2,
          hasMore: true,
        ),
      );
      await tester.pumpAndSettle();

      await robot.scrollToItem('p29');
      await tester.pump();
      await tester.pump();
      expect(requests[2], hasLength(1));

      requests[2]!.single.completeError(StateError('page failed'));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(DropifyKeys.paginationErrorRow), findsOneWidget);
      expect(find.byKey(DropifyKeys.itemRow('p29')), findsOneWidget);

      await tester.ensureVisible(find.byKey(DropifyKeys.paginationRetryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(DropifyKeys.paginationRetryButton));
      await tester.pump();
      expect(requests[1], hasLength(1));
      expect(requests[2], hasLength(2));

      requests[2]!.last.complete(
        DropifyPageResult<String, int>(
          items: _pagedItems(start: 30, count: 1),
          nextPageKey: null,
          hasMore: false,
        ),
      );
      await tester.pumpAndSettle();

      await robot.scrollToItem('p30');
      expect(find.byKey(DropifyKeys.itemRow('p30')), findsOneWidget);
    },
  );

  testWidgets(
    'paginated search resets pages and ignores stale page responses',
    (tester) async {
      final requests = <String, Completer<DropifyPageResult<String, int>>>{};
      await tester.pumpWidget(
        _Harness(
          alignment: Alignment.topCenter,
          child: DropifyPaginatedDropdown<String, int>(
            value: null,
            firstPageKey: 1,
            searchDebounceDuration: const Duration(milliseconds: 10),
            pageLoader: (request) {
              final completer = Completer<DropifyPageResult<String, int>>();
              requests['${request.query.normalizedText}:${request.pageKey}'] =
                  completer;
              return completer.future;
            },
            onChanged: (_) {},
          ),
        ),
      );
      final robot = _DropifyRobot(tester);

      await robot.open();
      requests[':1']!.complete(
        DropifyPageResult<String, int>(
          items: _pagedItems(start: 0, count: 30),
          nextPageKey: 2,
          hasMore: true,
        ),
      );
      await tester.pumpAndSettle();
      await robot.scrollToItem('p29');
      await tester.pump();
      expect(requests.containsKey(':2'), isTrue);

      await tester.enterText(find.byKey(DropifyKeys.searchInput), 'needle');
      await tester.pump(const Duration(milliseconds: 10));
      expect(requests.containsKey('needle:1'), isTrue);

      requests[':2']!.complete(
        DropifyPageResult<String, int>(
          items: _pagedItems(start: 30, count: 1),
          nextPageKey: null,
          hasMore: false,
        ),
      );
      requests['needle:1']!.complete(
        const DropifyPageResult<String, int>(
          items: <DropifyItem<String>>[
            DropifyItem(value: 'needle', label: 'Needle result'),
          ],
          nextPageKey: null,
          hasMore: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(DropifyKeys.itemRow('needle')), findsOneWidget);
      expect(find.byKey(DropifyKeys.itemRow('p30')), findsNothing);
    },
  );

  testWidgets('paginated multi selections persist across pages and searches', (
    tester,
  ) async {
    final requests = <String, Completer<DropifyPageResult<String, int>>>{};
    var values = <String>[];
    await tester.pumpWidget(
      _Harness(
        alignment: Alignment.topCenter,
        child: StatefulBuilder(
          builder: (context, setState) {
            return DropifyPaginatedDropdown<String, int>.multi(
              values: values,
              firstPageKey: 1,
              searchDebounceDuration: const Duration(milliseconds: 10),
              pageLoader: (request) {
                final completer = Completer<DropifyPageResult<String, int>>();
                requests['${request.query.normalizedText}:${request.pageKey}'] =
                    completer;
                return completer.future;
              },
              onChanged: (nextValues) => setState(() => values = nextValues),
            );
          },
        ),
      ),
    );
    final robot = _DropifyRobot(tester);

    await robot.open();
    requests[':1']!.complete(
      DropifyPageResult<String, int>(
        items: _pagedItems(start: 0, count: 30),
        nextPageKey: 2,
        hasMore: true,
      ),
    );
    await tester.pumpAndSettle();
    await robot.selectItem('p0');

    await robot.scrollToItem('p29');
    await tester.pump();
    requests[':2']!.complete(
      DropifyPageResult<String, int>(
        items: _pagedItems(start: 30, count: 1),
        nextPageKey: null,
        hasMore: false,
      ),
    );
    await tester.pumpAndSettle();
    await robot.scrollToItem('p30');
    await robot.selectItem('p30');

    await tester.enterText(find.byKey(DropifyKeys.searchInput), 'needle');
    await tester.pump(const Duration(milliseconds: 10));
    requests['needle:1']!.complete(
      const DropifyPageResult<String, int>(
        items: <DropifyItem<String>>[
          DropifyItem(value: 'needle', label: 'Needle result'),
        ],
        nextPageKey: null,
        hasMore: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(values, <String>['p0', 'p30']);
    expect(find.byKey(DropifyKeys.selectedChip('p0')), findsOneWidget);
    expect(find.byKey(DropifyKeys.selectedChip('p30')), findsOneWidget);
    expect(find.byKey(DropifyKeys.menuOverlay), findsOneWidget);
  });
}

List<DropifyItem<String>> _pagedItems({
  required int start,
  required int count,
}) {
  return List<DropifyItem<String>>.generate(count, (index) {
    final value = 'p${start + index}';
    return DropifyItem(value: value, label: 'Page item ${start + index}');
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.child, this.alignment = Alignment.center});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: alignment,
          child: SizedBox(width: 280, child: child),
        ),
      ),
    );
  }
}

class _DropifyRobot {
  const _DropifyRobot(this.tester);

  final WidgetTester tester;

  Future<void> open() async {
    await tester.tap(find.byKey(DropifyKeys.field));
    await tester.pumpAndSettle();
  }

  Future<void> search(String text) async {
    await tester.enterText(find.byKey(DropifyKeys.searchInput), text);
    await tester.pumpAndSettle();
  }

  Future<void> selectItem(Object identity) async {
    await tester.tap(find.byKey(DropifyKeys.itemRow(identity)));
    await tester.pumpAndSettle();
  }

  Future<void> clearAll() async {
    await tester.tap(find.byKey(DropifyKeys.clearAll));
    await tester.pumpAndSettle();
  }

  Future<void> selectVisible() async {
    await tester.tap(find.byKey(DropifyKeys.selectAll));
    await tester.pumpAndSettle();
  }

  Future<void> retry() async {
    await tester.tap(find.byKey(DropifyKeys.retryButton));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToItem(Object identity) async {
    await tester.scrollUntilVisible(
      find.byKey(DropifyKeys.itemRow(identity)),
      280,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
  }
}
