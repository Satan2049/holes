import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:holes/main.dart';

void main() {
  testWidgets('Holes app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HolesApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
