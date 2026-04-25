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
}

class _Harness extends StatelessWidget {
  const _Harness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 280, child: child)),
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
}
