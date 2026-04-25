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
}
