import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_design/view/contact_view.dart';

void main() {
  testWidgets('App should open contact screen as home', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ContactView()));

    expect(find.text('Contacts'), findsOneWidget);
  });
}
