enum ElderlyHelpRequestStatus {
  pending('PENDING'),
  acknowledged('ACKNOWLEDGED'),
  resolved('RESOLVED');

  const ElderlyHelpRequestStatus(this.apiValue);

  final String apiValue;

  static ElderlyHelpRequestStatus parse(Object? value) {
    return values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => throw const FormatException('Unknown help request status.'),
    );
  }
}

class ElderlyHelpRequest {
  const ElderlyHelpRequest({
    required this.id,
    required this.patientId,
    required this.status,
    required this.message,
    required this.clientActionId,
    required this.requestedAt,
    required this.acknowledgedByUserId,
    required this.acknowledgedAt,
    required this.resolvedByUserId,
    required this.resolvedAt,
    required this.updatedAt,
    required this.patientDisplayName,
    required this.idempotent,
  });

  final String id;
  final String patientId;
  final ElderlyHelpRequestStatus status;
  final String? message;
  final String clientActionId;
  final DateTime requestedAt;
  final String? acknowledgedByUserId;
  final DateTime? acknowledgedAt;
  final String? resolvedByUserId;
  final DateTime? resolvedAt;
  final DateTime updatedAt;
  final String? patientDisplayName;
  final bool idempotent;

  factory ElderlyHelpRequest.fromJson(Map<String, dynamic> json) {
    return ElderlyHelpRequest(
      id: _requiredString(json, 'help_request_id'),
      patientId: _requiredString(json, 'patient_id'),
      status: ElderlyHelpRequestStatus.parse(json['status']),
      message: _nullableString(json, 'message'),
      clientActionId: _requiredString(json, 'client_action_id'),
      requestedAt: _requiredDateTime(json, 'requested_at'),
      acknowledgedByUserId: _nullableString(json, 'acknowledged_by_user_id'),
      acknowledgedAt: _nullableDateTime(json, 'acknowledged_at'),
      resolvedByUserId: _nullableString(json, 'resolved_by_user_id'),
      resolvedAt: _nullableDateTime(json, 'resolved_at'),
      updatedAt: _requiredDateTime(json, 'updated_at'),
      patientDisplayName: _nullableString(json, 'patient_display_name'),
      idempotent: _requiredBool(json, 'idempotent'),
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid $key.');
    }

    return value;
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Invalid $key.');
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! bool) {
      throw FormatException('Invalid $key.');
    }

    return value;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = _requiredString(json, key);
    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      throw FormatException('Invalid $key.');
    }

    return parsed.toUtc();
  }

  static DateTime? _nullableDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Invalid $key.');
    }

    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      throw FormatException('Invalid $key.');
    }

    return parsed.toUtc();
  }
}
