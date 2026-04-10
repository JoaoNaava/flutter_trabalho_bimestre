import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart'; // ✅ corrigido (sem /lib)

void main() {
  testWidgets('App loads Birdle correctly', (WidgetTester tester) async {
    // Build do app
    await tester.pumpWidget(const MyApp());

    // Verifica se o título aparece
    expect(find.text('Birdle'), findsOneWidget);

    // Verifica se existe pelo menos um Tile (Container)
    expect(find.byType(Container), findsWidgets);
  });
}