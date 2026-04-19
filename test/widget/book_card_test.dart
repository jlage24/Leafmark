import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:leafmark/features/books/domain/models/book.dart';
import 'package:leafmark/features/books/presentation/widgets/book_card.dart';

void main() {
  group('BookCard', () {
    // Objeto real com todas as propriedades required
    final testBook = Book(
      id: '1',
      isbn: '9780141036144',
      title: 'Livro de Teste',
      authors: 'Autor de Teste',
      condition: BookCondition.good,
      addedAt: DateTime.parse('2025-01-01T00:00:00.000'),
      coverUrl: 'https://example.com/cover.jpg',
    );

    testWidgets('Should display book tittle', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookCard(book: testBook, onTap: () {}),
            ),
          ),
        );

        // O texto aqui tem de ser exatamente igual ao title do teu testBook
        expect(find.text('Livro de Teste'), findsOneWidget);
      });
    });

    testWidgets('Should display the author', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookCard(book: testBook, onTap: () {}),
            ),
          ),
        );

        expect(find.text('Autor de Teste'), findsOneWidget);
      });
    });

    testWidgets('tap, no card should trigger a callback onTap', (tester) async {
      bool tapped = false;

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookCard(
                book: testBook,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        // Simula o clique no cartão inteiro
        await tester.tap(find.byType(BookCard));
        await tester.pump();

        expect(tapped, isTrue);
      });
    });
  });
}