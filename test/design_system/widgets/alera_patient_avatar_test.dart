import 'dart:async';
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

class _FailingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FailingHttpClient();
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

      final CircleAvatar avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatar.backgroundImage, isNull);
    });

    testWidgets('renders initials when photoUrl is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const AleraPatientAvatar(name: 'Maria Santos', photoUrl: '')),
      );

      expect(find.text('MS'), findsOneWidget);

      final CircleAvatar avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatar.backgroundImage, isNull);
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

      final CircleAvatar avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );

      expect(avatar.backgroundImage, isA<NetworkImage>());
      expect(
        (avatar.backgroundImage as NetworkImage).url,
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

        final CircleAvatar avatar = tester.widget<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(avatar.backgroundImage, isNull);
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
        final CircleAvatar avatar = tester.widget<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(avatar.backgroundImage, isA<NetworkImage>());
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

      expect(find.bySemanticsLabel('Maria Santos avatar'), findsOneWidget);
      handle.dispose();
    });
  });
}
