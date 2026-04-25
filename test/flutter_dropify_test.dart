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
}
