// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';

import 'package:todoapp/main.dart';

void main() {
  testWidgets('Todo app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TodoApp());

    // Verify that the app starts with the title
    expect(find.text('Smart Todo'), findsOneWidget);
    expect(find.text('Stay organized, stay productive'), findsOneWidget);

    // Verify that we have sample tasks
    expect(find.text('Complete Flutter project'), findsOneWidget);
    expect(find.text('Buy groceries'), findsOneWidget);
    expect(find.text('Study for exam'), findsOneWidget);

    // Verify that the add task button is present
    expect(find.text('Add Task'), findsOneWidget);
  });
}
