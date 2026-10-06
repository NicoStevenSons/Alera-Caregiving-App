class HelpRequestNoteRecord {
  const HelpRequestNoteRecord({
    required this.id,
    required this.helpRequestId,
    required this.authorUserId,
    required this.clientActionId,
    required this.note,
    required this.createdAt,
    required this.authorDisplayName,
    required this.idempotent,
  });

  final String id;
  final String helpRequestId;
  final String authorUserId;
  final String clientActionId;
  final String note;
  final DateTime createdAt;
  final String? authorDisplayName;
  final bool idempotent;

  factory HelpRequestNoteRecord.fromJson(Map<String, dynamic> json) {
    return HelpRequestNoteRecord(
      id: _requiredString(json, 'help_request_note_id'),
      helpRequestId: _requiredString(json, 'help_request_id'),
      authorUserId: _requiredString(json, 'author_user_id'),
      clientActionId: _requiredString(json, 'client_action_id'),
      note: _requiredString(json, 'note'),
      createdAt: _requiredDateTime(json, 'created_at'),
      authorDisplayName: _nullableString(json, 'author_display_name'),
      idempotent: _requiredBool(json, 'idempotent'),
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid $key.');
    }

    return value.trim();
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value == null) return null;
    if (value is! String) throw FormatException('Invalid $key.');

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = _requiredString(json, key);
    final parsed = DateTime.tryParse(value);

    if (parsed == null) throw FormatException('Invalid $key.');

    return parsed.toUtc();
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];

    if (value is! bool) throw FormatException('Invalid $key.');

    return value;
  }
}

class HelpRequestNotePage {
  const HelpRequestNotePage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<HelpRequestNoteRecord> items;
  final int total;
  final int limit;
  final int offset;
}
