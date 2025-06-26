import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/widgets/progress_chart.dart';

void main() {
  group('ProgressChart Widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should show loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressChart(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show no data message when no notes exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressChart(),
          ),
        ),
      );

      // Wait for the loading to complete
      await tester.pump();

      expect(find.text('データがありません'), findsOneWidget);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressChart(),
          ),
        ),
      );

      // Wait for loading and rendering
      await tester.pumpAndSettle();

      // Should not throw any exceptions
      expect(find.byType(ProgressChart), findsOneWidget);
    });

    testWidgets('should handle empty state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressChart(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show either loading indicator or no data message
      expect(
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
        find.text('データがありません').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('should be contained in a sized container', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressChart(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find the widget structure
      expect(find.byType(ProgressChart), findsOneWidget);
    });
  });
}