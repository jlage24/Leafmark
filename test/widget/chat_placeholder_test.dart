import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leafmark/features/chat/presentation/screens/chat_placeholder_screen.dart';

void main() {
  group('ChatPlaceholderScreen', () {
    testWidgets('deve renderizar sem erros', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ChatPlaceholderScreen()),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('deve mostrar textos indicativos de que o chat chega em breve', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ChatPlaceholderScreen()),
      );

      expect(find.text('Chat is coming soon'), findsOneWidget);
      expect(find.text('Secure messaging between traders is on the way.'), findsOneWidget);
    });
  });
}