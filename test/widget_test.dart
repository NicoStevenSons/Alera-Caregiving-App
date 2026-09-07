import 'package:alera/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts at Welcome without a saved session', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const AleraApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Alera'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Choose Interface'), findsNothing);
  });
}
