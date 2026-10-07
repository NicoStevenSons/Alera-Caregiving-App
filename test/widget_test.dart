import 'package:alera/interfaces/interface_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts at Welcome without a saved session', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: InterfaceSelection()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Alera'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Choose Interface'), findsNothing);
  });
}
