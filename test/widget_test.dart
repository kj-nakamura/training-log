import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:training_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TrainingApp());
    await tester.pumpAndSettle();

    // Verify that our app loads without errors
    expect(find.text('📝 トレーニングノート'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });
}
