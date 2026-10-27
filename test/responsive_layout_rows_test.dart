import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hulp_admin/components/responsive_layout_rows.dart';

void main() {
  Future<void> pumpAtWidth(
      WidgetTester tester, double width, Widget child) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('stacks form fields below the dialog breakpoint', (tester) async {
    await pumpAtWidth(
      tester,
      390,
      ResponsiveFormRow(
        children: [
          Flexible(
            child: SizedBox(
              height: 48,
              child:
                  TextField(decoration: const InputDecoration(labelText: 'A')),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: SizedBox(
              height: 48,
              child:
                  TextField(decoration: const InputDecoration(labelText: 'B')),
            ),
          ),
        ],
      ),
    );

    final rowFinder = find.byType(ResponsiveFormRow);
    expect(
      find.descendant(of: rowFinder, matching: find.byType(Column)),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps form fields in a row when the dialog is wide',
      (tester) async {
    await pumpAtWidth(
      tester,
      900,
      ResponsiveFormRow(
        children: [
          const Flexible(child: SizedBox(height: 48)),
          const SizedBox(width: 8),
          const Flexible(child: SizedBox(height: 48)),
        ],
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ResponsiveFormRow),
        matching: find.byType(Row),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps toolbar controls in a narrow viewport', (tester) async {
    await pumpAtWidth(
      tester,
      320,
      ResponsiveToolbarRow(
        children: const [
          Expanded(child: SizedBox(width: 180, height: 48)),
          SizedBox(width: 16),
          Expanded(child: SizedBox(width: 180, height: 48)),
        ],
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ResponsiveToolbarRow),
        matching: find.byType(Wrap),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves the toolbar row on wide screens', (tester) async {
    await pumpAtWidth(
      tester,
      1200,
      ResponsiveToolbarRow(
        children: const [
          Expanded(child: SizedBox(width: 180, height: 48)),
          SizedBox(width: 16),
          Expanded(child: SizedBox(width: 180, height: 48)),
        ],
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ResponsiveToolbarRow),
        matching: find.byType(Row),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wraps the toolbar at compact tablet width', (tester) async {
    await pumpAtWidth(
      tester,
      900,
      ResponsiveToolbarRow(
        children: const [
          Expanded(child: SizedBox(width: 180, height: 48)),
          SizedBox(width: 16),
          Expanded(child: SizedBox(width: 180, height: 48)),
        ],
      ),
    );

    expect(
      find.descendant(
        of: find.byType(ResponsiveToolbarRow),
        matching: find.byType(Wrap),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses space between for a wide page heading and action',
      (tester) async {
    await pumpAtWidth(
      tester,
      1200,
      const ResponsiveSpaceBetween(
        leading: Text('Registro talento Hulp'),
        trailing: SizedBox(width: 200, height: 48),
      ),
    );

    final row = tester.widget<Row>(
      find.descendant(
        of: find.byType(ResponsiveSpaceBetween),
        matching: find.byType(Row),
      ),
    );
    expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    expect(tester.takeException(), isNull);
  });

  testWidgets('centers the compact heading and stretches its action',
      (tester) async {
    await pumpAtWidth(
      tester,
      390,
      const ResponsiveSpaceBetween(
        leading: Text('Registro talento Hulp'),
        trailing: SizedBox(width: 200, height: 48),
      ),
    );

    final titleCenter = tester.getCenter(find.text('Registro talento Hulp'));
    final actionWidth = tester.getSize(find.byType(SizedBox).last).width;
    expect(titleCenter.dx, closeTo(195, 1));
    expect(actionWidth, 390);
    expect(
      find.descendant(
        of: find.byType(ResponsiveSpaceBetween),
        matching: find.byType(Column),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a heading without an action left aligned on wide screens',
      (tester) async {
    await pumpAtWidth(
      tester,
      1200,
      const ResponsiveSpaceBetween(
        leading: Text('Solicitudes rechazadas'),
      ),
    );

    expect(
      tester.getTopLeft(find.text('Solicitudes rechazadas')).dx,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps filter controls together when wrapping', (tester) async {
    await pumpAtWidth(
      tester,
      320,
      const ResponsiveToolbarGroup(
        children: [
          Text('Filtrar por:'),
          SizedBox(width: 200, height: 48),
          SizedBox(width: 180, height: 48),
        ],
      ),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('centers the compact filter label, selectors and summary',
      (tester) async {
    await pumpAtWidth(
      tester,
      390,
      ResponsiveProviderFilterLayout(
        label: const Text('Filtrar por:'),
        filters: [
          ResponsiveFilterField(
            selector: Container(key: const ValueKey('category'), height: 48),
          ),
          ResponsiveFilterField(
            selector: Container(key: const ValueKey('city'), height: 48),
          ),
        ],
        summary: const Text('Pendientes   Rechazadas   Total'),
      ),
    );

    final labelCenter = tester.getCenter(find.text('Filtrar por:'));
    final category = tester.getRect(find.byKey(const ValueKey('category')));
    final city = tester.getRect(find.byKey(const ValueKey('city')));
    final summaryCenter = tester.getCenter(
      find.text('Pendientes   Rechazadas   Total'),
    );

    expect(labelCenter.dx, closeTo(195, 1));
    expect(category.center.dy, closeTo(city.center.dy, 1));
    expect(category.right, lessThan(city.left));
    expect(summaryCenter.dy, greaterThan(category.bottom));
    expect(summaryCenter.dx, closeTo(195, 1));
    expect(tester.takeException(), isNull);
  });
}
