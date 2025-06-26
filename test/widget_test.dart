import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:training_app/main.dart';

void main() {
  group('TrainingApp Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('App should start and display main screen', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Check if the main screen elements are present
      expect(find.text('📝 トレーニングノート'), findsOneWidget);
      
      // Check for navigation elements
      expect(find.byIcon(Icons.calendar_today), findsWidgets);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('Should display body weight input field', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Check for body weight section
      expect(find.byIcon(Icons.monitor_weight), findsOneWidget);
    });

    testWidgets('Should display exercise input section', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Should have at least one exercise card with empty exercise
      expect(find.text('種目名未設定'), findsOneWidget);
    });

    testWidgets('Should be able to add new exercise', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Find and tap add exercise button
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsWidgets);
      
      await tester.tap(addButton.first);
      await tester.pumpAndSettle();

      // Should have two exercise cards now
      expect(find.text('種目名未設定'), findsNWidgets(2));
    });

    testWidgets('Should navigate between dates using arrow buttons', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Tap right arrow to go to next day
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Should still be on training note screen
      expect(find.text('📝 トレーニングノート'), findsOneWidget);
      
      // Tap left arrow to go to previous day
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      
      expect(find.text('📝 トレーニングノート'), findsOneWidget);
    });

    testWidgets('Should handle empty state properly', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Check empty state message for exercises
      expect(find.text('トレーニング内容が記録されていません'), findsOneWidget);
    });

    testWidgets('Should be able to enter exercise name in edit mode', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Find exercise name field and enter text
      final exerciseField = find.byType(TextFormField).first;
      await tester.enterText(exerciseField, 'ベンチプレス');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('ベンチプレス'), findsOneWidget);
    });

    testWidgets('Should display set input fields', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Should find weight and reps input fields
      expect(find.text('重量 (kg) *'), findsWidgets);
      expect(find.text('回 *'), findsWidgets);
    });

    testWidgets('Should have navigation bottom bar', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Check for bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Should navigate to calendar screen', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Find and tap the calendar tab in bottom navigation
      await tester.tap(find.byIcon(Icons.calendar_today).last);
      await tester.pumpAndSettle();

      // Check if calendar screen is displayed
      expect(find.text('📅 トレーニングカレンダー'), findsOneWidget);
    });

    testWidgets('Should navigate to report screen', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Find and tap the report tab in bottom navigation
      await tester.tap(find.byIcon(Icons.bar_chart));
      await tester.pumpAndSettle();

      // Check if report screen is displayed
      expect(find.text('📊 トレーニングレポート'), findsOneWidget);
    });

    testWidgets('Should return to note screen from other screens', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Navigate to report screen
      await tester.tap(find.byIcon(Icons.bar_chart));
      await tester.pumpAndSettle();
      expect(find.text('📊 トレーニングレポート'), findsOneWidget);

      // Navigate back to note screen
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      expect(find.text('📝 トレーニングノート'), findsOneWidget);
    });
  });

  group('Report Screen Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Should show empty state in report screen', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Navigate to report screen
      await tester.tap(find.byIcon(Icons.bar_chart));
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('まだトレーニング記録がありません'), findsOneWidget);
    });

    testWidgets('Should have add button for max exercises', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Navigate to report screen
      await tester.tap(find.byIcon(Icons.bar_chart));
      await tester.pumpAndSettle();

      // Should have add button in app bar
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('Calendar Screen Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Should display calendar properly', (WidgetTester tester) async {
      await tester.pumpWidget(const TrainingApp());
      await tester.pumpAndSettle();

      // Navigate to calendar screen
      await tester.tap(find.byIcon(Icons.calendar_today).last);
      await tester.pumpAndSettle();

      // Check if calendar is displayed
      expect(find.text('📅 トレーニングカレンダー'), findsOneWidget);
    });
  });
}