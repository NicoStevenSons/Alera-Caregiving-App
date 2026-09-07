import 'dart:convert';
import 'dart:async';

import 'package:alera/features/caregiver/data/auth/caregiver_auth_api.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:alera/features/caregiver/data/auth/caregiver_token_store.dart';
import 'package:alera/features/caregiver/presentation/auth/caregiver_auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('household validation is public and returns its name', () async {
    final api = CaregiverAuthApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/household/validate');
        expect(request.headers['authorization'], isNull);
        expect(jsonDecode(request.body), {'household_code': '4V8F-29HC'});
        return http.Response(
          '{"valid":true,"household_name":"Alera Test Household"}',
          200,
        );
      }),
    );
    final result = await api.validateHousehold(householdCode: '4V8F-29HC');
    expect(result.householdName, 'Alera Test Household');
  });

  test(
    'household validation distinguishes not found and network failures',
    () async {
      final missing = CaregiverAuthApi(
        client: MockClient((_) async => http.Response('{}', 404)),
      );
      await expectLater(
        missing.validateHousehold(householdCode: 'AAAA-BBBB'),
        throwsA(isA<HouseholdNotFoundFailure>()),
      );
      final offline = CaregiverAuthApi(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(
        offline.validateHousehold(householdCode: 'AAAA-BBBB'),
        throwsA(isA<HouseholdValidationFailure>()),
      );
    },
  );

  test('successful demo login persists and restores the session', () async {
    final _MemoryTokenStore store = _MemoryTokenStore();
    final CaregiverAuthApi authApi = CaregiverAuthApi(
      client: MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/auth/caregiver/login');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), {
          'household_code': 'TEST-HOUSEHOLD',
          'email': 'caregiver@example.test',
          'password': 'test-password',
        });
        return http.Response(
          jsonEncode({
            'access_token': 'test-access-token',
            'token_type': 'bearer',
            'expires_at': '2026-09-05T12:00:00Z',
            'actor': {
              'user_id': '11111111-1111-1111-1111-111111111111',
              'full_name': 'Test Caregiver',
              'role': 'CAREGIVER',
              'household_id': '22222222-2222-2222-2222-222222222222',
              'household_name': 'Test Household',
              'household_code': 'TEST-HOUSEHOLD',
            },
          }),
          200,
        );
      }),
    );
    final CaregiverSessionController session = CaregiverSessionController(
      tokenStore: store,
      authApi: authApi,
    );

    await session.login(
      householdCode: 'TEST-HOUSEHOLD',
      email: 'caregiver@example.test',
      password: 'test-password',
    );

    expect(store.token, 'test-access-token');
    expect(session.status, CaregiverSessionStatus.authenticated);

    final CaregiverSessionController restored = CaregiverSessionController(
      tokenStore: store,
      authApi: authApi,
    );
    await restored.restoreSession();
    expect(restored.status, CaregiverSessionStatus.authenticated);
    expect(restored.accessToken, 'test-access-token');
  });

  test(
    'accepts deployed response when default token_type is omitted',
    () async {
      final CaregiverAuthApi authApi = CaregiverAuthApi(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'access_token': 'default-bearer-token',
              'expires_at': '2026-09-05T12:00:00Z',
              'actor': {
                'user_id': '11111111-1111-1111-1111-111111111111',
                'full_name': 'Test Caregiver',
                'role': 'CAREGIVER',
                'household_id': '22222222-2222-2222-2222-222222222222',
                'household_name': 'Test Household',
                'household_code': 'TEST-HOUSEHOLD',
              },
            }),
            200,
          ),
        ),
      );

      final String token = await authApi.login(
        householdCode: 'TEST-HOUSEHOLD',
        email: 'caregiver@example.test',
        password: 'test-password',
      );

      expect(token, 'default-bearer-token');
    },
  );

  testWidgets('failed login shows a useful generic error', (
    WidgetTester tester,
  ) async {
    final CaregiverSessionController session = CaregiverSessionController(
      tokenStore: _MemoryTokenStore(),
      authApi: CaregiverAuthApi(
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/household/validate') {
            return http.Response(
              '{"valid":true,"household_name":"Alera Test Household"}',
              200,
            );
          }
          return http.Response('invalid', 401);
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: HouseholdAuthFlow(sessionController: session)),
    );

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
    expect(find.text('Signing in to Alera Test Household'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('caregiver-email-field')),
      'caregiver@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('caregiver-password-field')),
      'wrong-password',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-error')), findsOneWidget);
    expect(find.text('Unable to sign in. Check your details.'), findsOneWidget);
    expect(session.status, CaregiverSessionStatus.restoring);
  });

  testWidgets('validation prevents duplicates, supports retry, Edit and Back', (
    tester,
  ) async {
    final first = Completer<http.Response>();
    var validationCalls = 0;
    final session = CaregiverSessionController(
      tokenStore: _MemoryTokenStore(),
      authApi: CaregiverAuthApi(
        client: MockClient((request) {
          validationCalls++;
          if (validationCalls == 1) return first.future;
          return Future.value(
            http.Response(
              '{"valid":true,"household_name":"Retry Household"}',
              200,
            ),
          );
        }),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: HouseholdAuthFlow(sessionController: session)),
    );
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’m a Caregiver'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household-code-field')),
      '4v8f-29hc',
    );
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Validating…'), findsOneWidget);
    await tester.tap(find.text('Validating…'));
    expect(validationCalls, 1);
    first.complete(http.Response('', 500));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'We couldn’t verify the household right now. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Signing in to Retry Household'), findsOneWidget);
    expect(find.text('4V8F-29HC'), findsNothing);
    await tester.tap(find.text('Edit household'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('household-code-field')), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('household-code-field')))
          .controller
          ?.text,
      '4V8F-29HC',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('How will you use Alera?'), findsOneWidget);
  });

  testWidgets('unknown household remains on household entry', (tester) async {
    final session = CaregiverSessionController(
      tokenStore: _MemoryTokenStore(),
      authApi: CaregiverAuthApi(
        client: MockClient((_) async => http.Response('{}', 404)),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: HouseholdAuthFlow(sessionController: session)),
    );
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I’m a Caregiver'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('household-code-field')),
      '4V8F-29HC',
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('household-code-field')), findsOneWidget);
    expect(
      find.text(
        'We couldn’t find that household code. Check the code and try again.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('caregiver-email-field')), findsNothing);
  });
}

class _MemoryTokenStore implements CaregiverTokenStore {
  StoredSession? session;
  String? get token => session?.token;

  @override
  Future<void> clearSession() async => session = null;

  @override
  Future<StoredSession?> readSession() async => session;

  @override
  Future<void> writeSession(StoredSession session) async =>
      this.session = session;
}
