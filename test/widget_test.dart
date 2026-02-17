// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:intern_tracker/main.dart';

void main() {
  testWidgets('Notes list renders with pre-populated notes', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    // The four sample notes should be visible
    expect(find.text('Grocery List'), findsOneWidget);
    expect(find.text('Project Ideas'), findsOneWidget);
    expect(find.text('Meeting Notes'), findsOneWidget);
    expect(find.text('Book Recommendations'), findsOneWidget);
  });

  testWidgets('Tapping compose button creates a new note', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    // Tap the compose (square_pencil) icon to add a new note
    await tester.tap(find.byIcon(CupertinoIcons.square_pencil));
    await tester.pumpAndSettle();

    // Should navigate to the note editor
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('Tapping a note opens the editor with its content', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grocery List'));
    await tester.pumpAndSettle();

    // Editor should show the title and Done button
    expect(find.text('Grocery List'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('Done button returns to the notes list', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grocery List'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Back on the list — large title should be visible
    expect(find.text('Notes'), findsOneWidget);
  });
}
