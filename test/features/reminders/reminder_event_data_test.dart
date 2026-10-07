import 'dart:convert';

import 'package:alera/features/caregiver/data/auth/caregiver_session_controller.dart';
import 'package:alera/features/reminders/data/reminder_api_data_source.dart';
import 'package:alera/features/reminders/data/reminder_event_dto.dart';
import 'package:alera/features/reminders/data/reminder_timeline_controller.dart';
import 'package:alera/features/reminders/domain/reminder_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'reminder_event_test_support.dart';

void main() {
  group('event DTO', () {
    test('parses a full event', () {
      final parsed = ReminderEventDto.fromJson(
        eventJson(
          type: 'SNOOZED',
          actorRole: 'PATIENT',
          note: 'Need ten more minutes',
          metadata: {'snoozed_until': '2026-10-07T07:10:00Z'},
        ),
      ).value;

      expect(parsed.id, 'e1');
      expect(parsed.occurrenceId, 'occ-1');
      expect(parsed.type, ReminderEventType.snoozed);
      expect(parsed.actorRole, ReminderActorRole.patient);
      expect(parsed.actorUserId, 'u1');
      expect(parsed.actorDisplayName, 'Maria Santos');
      expect(parsed.note, 'Need ten more minutes');
      expect(parsed.occurredAt, DateTime.utc(2026, 10, 7, 12));
      expect(parsed.occurredAt.isUtc, isTrue);
      expect(parsed.snoozedUntil, DateTime.utc(2026, 10, 7, 7, 10));
    });

    test('accepts null actor and null note', () {
      final parsed = ReminderEventDto.fromJson(
        eventJson(
          type: 'NOTIFICATION_SENT',
          actorUserId: null,
          actorRole: 'SYSTEM',
          actorName: null,
          note: null,
        ),
      ).value;

      expect(parsed.actorUserId, isNull);
      expect(parsed.actorDisplayName, isNull);
      expect(parsed.note, isNull);
      expect(parsed.actorRole, ReminderActorRole.system);
    });

    test('blank note and name are treated as missing', () {
      final parsed = ReminderEventDto.fromJson(
        eventJson(note: '   ', actorName: ''),
      ).value;
      expect(parsed.note, isNull);
      expect(parsed.actorDisplayName, isNull);
    });

    test('metadata is optional and tolerant', () {
      expect(
        ReminderEventDto.fromJson(eventJson(metadata: null)).value.metadata,
        isEmpty,
      );
      expect(
        ReminderEventDto.fromJson(eventJson(metadata: 'oops')).value.metadata,
        isEmpty,
      );
      final parsed = ReminderEventDto.fromJson(
        eventJson(
          type: 'NOTIFICATION_SENT',
          metadata: {'audience': 'PATIENT', 'channel': 'PUSH', 'x': 1},
        ),
      ).value;
      expect(parsed.metadata['x'], 1);
      expect(parsed.audience, 'PATIENT');
      expect(parsed.channel, 'PUSH');
      expect(parsed.snoozedUntil, isNull);
    });

    test('every documented event type parses', () {
      const types = {
        'CREATED': ReminderEventType.created,
        'NOTIFICATION_SENT': ReminderEventType.notificationSent,
        'SNOOZED': ReminderEventType.snoozed,
        'COMPLETED': ReminderEventType.completed,
        'COMPLETED_LATE': ReminderEventType.completedLate,
        'COMPLETED_ON_BEHALF': ReminderEventType.completedOnBehalf,
        'CANCELED': ReminderEventType.canceled,
        'MARKED_MISSED': ReminderEventType.markedMissed,
      };
      types.forEach((raw, expected) {
        expect(
          ReminderEventDto.fromJson(eventJson(type: raw)).value.type,
          expected,
        );
      });
    });

    test('unknown event type and role fall back instead of throwing', () {
      final parsed = ReminderEventDto.fromJson(
        eventJson(type: 'ESCALATED', actorRole: 'ROBOT'),
      ).value;
      expect(parsed.type, ReminderEventType.unknown);
      expect(parsed.rawType, 'ESCALATED');
      expect(parsed.actorRole, ReminderActorRole.unknown);

      final missing = ReminderEventDto.fromJson(
        eventJson(type: '', actorRole: null),
      ).value;
      expect(missing.type, ReminderEventType.unknown);
    });

    test('missing required fields are rejected', () {
      expect(
        () => ReminderEventDto.fromJson({'event_type': 'CREATED'}),
        throwsFormatException,
      );
      expect(
        () => ReminderEventDto.fromJson(eventJson(occurredAt: 'yesterday')),
        throwsFormatException,
      );
    });

    test('a page keeps the backend order', () {
      final page = parseReminderEventPage({
        'items': [
          eventJson(id: 'a', type: 'CREATED'),
          eventJson(id: 'b', type: 'NOTIFICATION_SENT'),
          eventJson(id: 'c', type: 'COMPLETED'),
        ],
        'total': 3,
        'limit': 50,
        'offset': 0,
      });
      expect(page.items.map((e) => e.id), ['a', 'b', 'c']);
      expect(page.total, 3);
    });
  });

  group('API data source', () {
    test('GETs the events endpoint with the bearer token and paging', () async {
      late http.Request captured;
      final source = ReminderApiDataSource(
        session: _Session('token'),
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'items': [eventJson()],
              'total': 1,
              'limit': 50,
              'offset': 0,
            }),
            200,
          );
        }),
      );

      final page = await source.fetchEvents('occ-1');

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/v1/reminders/occ-1/events');
      expect(captured.url.queryParameters, {'limit': '50', 'offset': '0'});
      expect(captured.headers['authorization'], 'Bearer token');
      expect(page.items.single.type, ReminderEventType.created);
    });

    test('404 and 401 map to failures with their status codes', () async {
      final session = _Session('token');
      var status = 404;
      final source = ReminderApiDataSource(
        session: session,
        client: MockClient((_) async => http.Response('{}', status)),
      );

      await expectLater(
        source.fetchEvents('occ-1'),
        throwsA(
          isA<ReminderApiFailure>().having((e) => e.statusCode, 'status', 404),
        ),
      );
      expect(session.cleared, isFalse);

      status = 401;
      await expectLater(
        source.fetchEvents('occ-1'),
        throwsA(
          isA<ReminderApiFailure>().having((e) => e.statusCode, 'status', 401),
        ),
      );
      expect(session.cleared, isTrue);
    });

    test('a malformed body becomes a readable failure', () async {
      final source = ReminderApiDataSource(
        session: _Session('token'),
        client: MockClient((_) async => http.Response('{"nope":1}', 200)),
      );
      await expectLater(
        source.fetchEvents('occ-1'),
        throwsA(isA<ReminderApiFailure>()),
      );
    });
  });

  group('timeline controller', () {
    ReminderTimelineController make(FakeEventsSource source, {int size = 2}) {
      final controller = ReminderTimelineController(
        dataSource: source,
        occurrenceId: 'occ-1',
        pageSize: size,
      );
      addTearDown(controller.dispose);
      return controller;
    }

    test('loads the first page oldest-first', () async {
      final source = FakeEventsSource([event(id: 'a'), event(id: 'b')]);
      final controller = make(source);
      final future = controller.load();
      expect(controller.loading, isTrue);
      await future;
      expect(controller.loading, isFalse);
      expect(controller.events.map((e) => e.id), ['a', 'b']);
      expect(controller.hasMore, isFalse);
    });

    test('empty history is its own state', () async {
      final controller = make(FakeEventsSource(const []));
      await controller.load();
      expect(controller.isEmpty, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('failure then retry succeeds', () async {
      final source = FakeEventsSource([event(id: 'a')])
        ..failures.add(const ReminderApiFailure('Offline'));
      final controller = make(source);
      await controller.load();
      expect(controller.errorMessage, 'Offline');
      expect(controller.isEmpty, isFalse);

      await controller.load();
      expect(controller.errorMessage, isNull);
      expect(controller.events, hasLength(1));
    });

    test('404 is flagged so the UI can stop offering retry', () async {
      final source = FakeEventsSource(const [])
        ..failures.add(const ReminderApiFailure('Gone', statusCode: 404));
      final controller = make(source);
      await controller.load();
      expect(controller.notFound, isTrue);
    });

    test('load more appends the next page without duplicates', () async {
      final source = FakeEventsSource([
        event(id: 'a'),
        event(id: 'b'),
        event(id: 'c'),
      ]);
      final controller = make(source);
      await controller.load();
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      expect(source.offsets, [0, 2]);
      expect(controller.events.map((e) => e.id), ['a', 'b', 'c']);
      expect(controller.hasMore, isFalse);
    });

    test('a failed load more keeps what is shown and can be retried', () async {
      final source = FakeEventsSource([
        event(id: 'a'),
        event(id: 'b'),
        event(id: 'c'),
      ]);
      final controller = make(source);
      await controller.load();
      source.failures.add(const ReminderApiFailure('Slow'));

      await controller.loadMore();
      expect(controller.loadMoreError, 'Slow');
      expect(controller.events, hasLength(2));
      expect(controller.errorMessage, isNull);

      await controller.loadMore();
      expect(controller.loadMoreError, isNull);
      expect(controller.events, hasLength(3));
    });

    test('an empty extra page cannot loop "load more" forever', () async {
      final source = FakeEventsSource([event(id: 'a')], total: 5);
      final controller = make(source);
      await controller.load();
      expect(controller.hasMore, isTrue);
      await controller.loadMore();
      expect(controller.hasMore, isFalse);
    });
  });
}

class _Session implements CaregiverSession {
  _Session(this.accessToken);
  @override
  String? accessToken;
  bool cleared = false;
  @override
  String? get householdCode => null;
  @override
  Future<void> clearInvalidSession() async {
    cleared = true;
    accessToken = null;
  }
}
