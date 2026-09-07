import 'dart:async';
import 'dart:convert';

import 'package:alera/Services/health_event_api_service.dart';

import 'package:alera/features/caregiver/caregiver_shell.dart';
import 'package:alera/features/caregiver/data/api/caregiver_alert_api_data_source.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_auth_api.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_token_store.dart';
import 'package:alera/features/caregiver/data/mock/mock_caregiver_repository.dart';
import 'package:alera/features/caregiver/presentation/auth/caregiver_auth_gate.dart';
import 'package:alera/features/patient/data/auth/patient_auth_api.dart';
import 'package:alera/interfaces/elderly_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite/sqflite.dart';

CaregiverSessionController controller(
  CaregiverTokenStore store, {
  http.Client? client,
}) => CaregiverSessionController(
  tokenStore: store,
  authApi: CaregiverAuthApi(
    client:
        client ??
        MockClient(
          (_) async => http.Response('{"access_token":"caregiver-token"}', 200),
        ),
  ),
  patientAuthApi: PatientAuthApi(
    client:
        client ??
        MockClient(
          (_) async => http.Response(
            '{"access_token":"patient-token","token_type":"bearer"}',
            200,
          ),
        ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SqflitePlugin.registerWith();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.alera.payloadextraction/payloads'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.tekartik.sqflite'),
      (call) async => switch (call.method) {
        'getDatabasesPath' => '/test',
        'openDatabase' => {'id': 1},
        'query' => <Object>[],
        _ => null,
      },
    );
  });

  test(
    'patient API sends only access code and accepts bearer response',
    () async {
      final api = PatientAuthApi(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/auth/patient/access');
          expect(request.headers['authorization'], isNull);
          expect(jsonDecode(request.body), {'access_code': 'access-code'});
          return http.Response(
            '{"access_token":"patient-token","token_type":"bearer"}',
            200,
          );
        }),
      );
      expect(await api.access(accessCode: 'access-code'), 'patient-token');
    },
  );

  for (final response in [
    http.Response('secret response', 401),
    http.Response('{}', 200),
    http.Response('[]', 200),
    http.Response('{"access_token":""}', 200),
    http.Response('{"access_token":"x","token_type":"basic"}', 200),
  ]) {
    test(
      'patient API safely rejects ${response.statusCode} ${response.body}',
      () async {
        final api = PatientAuthApi(client: MockClient((_) async => response));
        await expectLater(
          api.access(accessCode: 'code'),
          throwsA(isA<PatientAccessFailure>()),
        );
      },
    );
  }

  test('patient API safely handles timeout and network failure', () async {
    for (final error in [
      TimeoutException('timeout'),
      http.ClientException('network'),
    ]) {
      final api = PatientAuthApi(client: MockClient((_) async => throw error));
      await expectLater(
        api.access(accessCode: 'code'),
        throwsA(isA<PatientAccessFailure>()),
      );
    }
  });

  for (final type in SessionType.values) {
    test('secure storage restores and clears $type', () async {
      final store = SecureCaregiverTokenStore();
      final session = controller(store);
      if (type == SessionType.elderlyPatient) {
        await session.accessPatient(accessCode: 'code');
      } else {
        await session.login(
          householdCode: 'AAAA-BBBB',
          email: 'care@example.test',
          password: 'password',
        );
      }
      final saved = await const FlutterSecureStorage().readAll();
      expect(saved.keys, ['alera_session']);
      final restored = controller(SecureCaregiverTokenStore());
      await restored.restoreSession();
      expect(restored.sessionType, type);
      expect(restored.accessToken, session.accessToken);
      await restored.clearInvalidSession();
      expect(restored.accessToken, isNull);
      expect(restored.sessionType, isNull);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });
  }

  test(
    'legacy caregiver token migrates and malformed session fails closed',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'caregiver_access_token': 'old-token',
      });
      final store = SecureCaregiverTokenStore();
      expect((await store.readSession())?.type, SessionType.caregiver);
      expect((await const FlutterSecureStorage().readAll()).keys, [
        'alera_session',
      ]);
      for (final raw in [
        'not-json',
        '{"token":"x"}',
        '{"token":"x","type":"admin"}',
        '{"token":"","type":"caregiver"}',
      ]) {
        FlutterSecureStorage.setMockInitialValues({'alera_session': raw});
        expect(await store.readSession(), isNull);
        expect(await const FlutterSecureStorage().readAll(), isEmpty);
      }
    },
  );

  test(
    'logout prevents an in-flight patient login restoring the session',
    () async {
      final reply = Completer<http.Response>();
      final store = SecureCaregiverTokenStore();
      final session = controller(
        store,
        client: MockClient((_) => reply.future),
      );
      final login = session.accessPatient(accessCode: 'code');
      await session.logout();
      reply.complete(http.Response('{"access_token":"late-token"}', 200));
      await login;
      expect(session.status, CaregiverSessionStatus.unauthenticated);
      expect(await store.readSession(), isNull);
    },
  );

  test('patient JWT is not attached to health-event uploads', () async {
    final session = controller(SecureCaregiverTokenStore());
    await session.accessPatient(accessCode: 'code');
    expect(session.accessToken, 'patient-token');
    const uploads = HealthEventApiService(
      baseUrl: 'https://example.test',
      patientId: 'existing-test-patient',
    );
    await http.runWithClient(
      () => uploads.sendHealthEvent({'patient_id': uploads.patientId}),
      () => MockClient((request) async {
        expect(request.url.path, '/api/v1/health-events');
        expect(request.headers['authorization'], isNull);
        expect(request.body, isNot(contains('patient-token')));
        return http.Response('{}', 201);
      }),
    );
  });

  test('late caregiver 401 does not clear a newly signed-in patient', () async {
    final session = controller(SecureCaregiverTokenStore());
    await session.login(
      householdCode: 'AAAA-BBBB',
      email: 'care@example.test',
      password: 'password',
    );
    final reply = Completer<http.Response>();
    final api = CaregiverAlertApiDataSource(
      session: session,
      client: MockClient((_) => reply.future),
    );
    final request = api.fetchAlerts();
    final assertion = expectLater(
      request,
      throwsA(isA<CaregiverAlertsAuthFailure>()),
    );
    await session.logout();
    await session.accessPatient(accessCode: 'code');
    reply.complete(http.Response('', 401));
    await assertion;
    expect(session.sessionType, SessionType.elderlyPatient);
    expect(session.accessToken, 'patient-token');
  });

  testWidgets('role-first patient entry persists and routes on first success', (
    tester,
  ) async {
    final store = SecureCaregiverTokenStore();
    final session = controller(
      store,
      client: MockClient((request) async {
        expect(jsonDecode(request.body), {'access_code': '7K3M-9Q2D-R8TX'});
        return http.Response('{"access_token":"patient-token"}', 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverAuthGate(
          repository: const MockCaregiverRepository(),
          sessionController: session,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('How will you use Alera?'), findsOneWidget);
    expect(find.byKey(const Key('household-code-field')), findsNothing);
    await tester.tap(find.text('I’m a Patient'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter Patient Code'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('patient-access-code-field')),
      '7k3m 9q2d r8tx',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(ElderlyInterface), findsOneWidget);
    expect(find.text('Vitals'), findsOneWidget);
    expect(session.sessionType, SessionType.elderlyPatient);
    expect((await store.readSession())?.token, 'patient-token');
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Alera'), findsOneWidget);
    expect(await store.readSession(), isNull);
  });

  testWidgets('caregiver flow opens shell and More signs out', (tester) async {
    final store = SecureCaregiverTokenStore();
    final session = controller(
      store,
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/auth/household/validate') {
          expect(jsonDecode(request.body), {'household_code': 'AAAA-BBBB'});
          return http.Response(
            '{"valid":true,"household_name":"Alera Test Household"}',
            200,
          );
        }
        expect(request.url.path, '/api/v1/auth/caregiver/login');
        expect(jsonDecode(request.body), {
          'household_code': 'AAAA-BBBB',
          'email': 'care@example.test',
          'password': 'password',
        });
        return http.Response('{"access_token":"caregiver-token"}', 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CaregiverAuthGate(
          repository: const MockCaregiverRepository(),
          sessionController: session,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’m a Caregiver'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household-code-field')),
      'AAAA-BBBB',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('caregiver-email-field')),
      'care@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('caregiver-password-field')),
      'password',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(CaregiverShell), findsOneWidget);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Alera'), findsOneWidget);
    expect(await store.readSession(), isNull);
  });

  testWidgets(
    'used patient code stays on form with safe error; system Back works',
    (tester) async {
      final session = controller(
        SecureCaregiverTokenStore(),
        client: MockClient(
          (_) async => http.Response('private backend error', 401),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CaregiverAuthGate(
            repository: const MockCaregiverRepository(),
            sessionController: session,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I’m a Patient'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enter Patient Code'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('patient-access-code-field')),
        '7K3M-9Q2D-R8TX',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This patient code is invalid, expired, or has already been used. Ask your caregiver for a new one.',
        ),
        findsOneWidget,
      );
      expect(find.text('private backend error'), findsNothing);
      expect(session.accessToken, isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Connect to your care household'), findsOneWidget);
    },
  );

  for (final type in SessionType.values) {
    testWidgets(
      'restart routes $type to its real interface; 401 removes open routes',
      (tester) async {
        final store = SecureCaregiverTokenStore();
        await store.writeSession(StoredSession('stored-token', type));
        final session = controller(store);
        await tester.pumpWidget(
          MaterialApp(
            home: CaregiverAuthGate(
              repository: const MockCaregiverRepository(),
              sessionController: session,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final interface = find.byType(
          type == SessionType.elderlyPatient
              ? ElderlyInterface
              : CaregiverShell,
        );
        expect(interface, findsOneWidget);
        final navigator = Navigator.of(tester.element(interface));
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Open private detail')),
          ),
        );
        await tester.pumpAndSettle();
        final api = CaregiverAlertApiDataSource(
          session: session,
          client: MockClient((_) async => http.Response('', 401)),
        );
        await expectLater(
          api.fetchAlerts(),
          throwsA(isA<CaregiverAlertsAuthFailure>()),
        );
        await tester.pumpAndSettle();
        expect(find.text('Welcome to Alera'), findsOneWidget);
        expect(find.text('Open private detail'), findsNothing);
        expect(session.sessionType, isNull);
        expect(await store.readSession(), isNull);
      },
    );
  }
}
