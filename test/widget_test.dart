import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emie_odyssee/main.dart';

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const EmieOdysseeApp());
    expect(find.text("L'Île d'Émie"), findsOneWidget);
  });
}
