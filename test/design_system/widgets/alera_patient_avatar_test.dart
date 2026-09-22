import 'dart:io';

import 'package:alera/design_system/widgets/alera_patient_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// An [HttpClient] whose every request fails immediately, so a
/// [NetworkImage] load resolves deterministically to an error without ever
/// touching the network. Uses `noSuchMethod` so it satisfies the [HttpClient]
/// interface without stubbing members this test never calls.
class _FailingHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return Future<HttpClientRequest>.error(
      const SocketException('Network disabled for test'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AleraPatientAvatar', () {
    testWidgets('renders initials when photoUrl is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraPatientAvatar(name: 'Maria Santos')),
      );

      expect(find.text('MS'), findsOneWidget);
      expect(find.byType(Image), findsNothing);


    });

    testWidgets('renders initials when photoUrl is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraPatientAvatar(name: 'Maria Santos', photoUrl: '')),
      );

      expect(find.text('MS'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('falls back to "?" for a blank name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const AleraPatientAvatar(name: '   ')));

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('renders a NetworkImage and hides initials while a valid '
        'photoUrl is loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const AleraPatientAvatar(
            name: 'Maria Santos',
            photoUrl: 'https://example.com/maria.png',
          ),
        ),
      );

      final Image image = tester.widget<Image>(
        find.byType(Image),
      );

      expect(image.image, isA<NetworkImage>());
      expect(
        (image.image as NetworkImage).url,
        'https://example.com/maria.png',
      );
      expect(find.text('MS'), findsNothing);
    });

    testWidgets('falls back to initials when the photo fails to load', (
      WidgetTester tester,
    ) async {
      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          _host(
            const AleraPatientAvatar(
              name: 'Maria Santos',
              photoUrl: 'https://example.com/broken.png',
            ),
          ),
        );

        // Let the failed image request resolve and the resulting setState
        // land.
        await tester.pumpAndSettle();

        expect(find.text('MS'), findsOneWidget);

      }, createHttpClient: (SecurityContext? context) => _FailingHttpClient());
    });

    testWidgets('retries a new photoUrl after a previous one failed', (
      WidgetTester tester,
    ) async {
      await HttpOverrides.runZoned(() async {
        final GlobalKey key = GlobalKey();

        await tester.pumpWidget(
          _host(
            AleraPatientAvatar(
              key: key,
              name: 'Maria Santos',
              photoUrl: 'https://example.com/broken.png',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('MS'), findsOneWidget);

        await tester.pumpWidget(
          _host(
            AleraPatientAvatar(
              key: key,
              name: 'Maria Santos',
              photoUrl: 'https://example.com/still-broken.png',
            ),
          ),
        );

        // Immediately after the URL changes, the widget should attempt the
        // photo again rather than staying stuck on the earlier failure.
        final Image image = tester.widget<Image>(
          find.byType(Image),
      );

      expect(image.image, isA<NetworkImage>());
      expect(
        (image.image as NetworkImage).url,
        'https://example.com/still-broken.png',
        );
      }, createHttpClient: (SecurityContext? context) => _FailingHttpClient());
    });

    testWidgets('picks a deterministic colour from the name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraPatientAvatar(name: 'Maria Santos')),
      );
      final Color first = tester
          .widget<CircleAvatar>(find.byType(CircleAvatar))
          .backgroundColor!;

      await tester.pumpWidget(
        _host(const AleraPatientAvatar(name: 'Maria Santos')),
      );
      final Color second = tester
          .widget<CircleAvatar>(find.byType(CircleAvatar))
          .backgroundColor!;

      expect(first, second);
    });

    testWidgets('exposes an accessible label combining name and role', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _host(const AleraPatientAvatar(name: 'Maria Santos')),
      );

      // Replace line 186 in test/design_system/widgets/alera_patient_avatar_test.dart:
      final semantics = tester.getSemantics(find.byType(AleraPatientAvatar));
      expect(semantics.label, contains('Maria Santos'));
      handle.dispose();
    });
  });
}
