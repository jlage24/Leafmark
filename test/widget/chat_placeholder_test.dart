import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/chat/presentation/screens/chat_screen.dart';

void main() {
  group('ChatPlaceholderScreen', () {
    testWidgets('SHould render with no errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ChatPlaceholderScreen()),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('Should display text indicating that chat is coming soon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ChatPlaceholderScreen()),
      );

      expect(find.text('Chat is coming soon'), findsOneWidget);
      expect(find.text('Secure messaging between traders is on the way.'), findsOneWidget);
    });
  });
}