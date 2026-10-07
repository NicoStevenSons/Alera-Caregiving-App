import 'package:alera/features/caregiver/domain/relationship_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes whitespace and treats blank as unset', () {
    expect(normalizeRelationshipLabel('  Grand   mother \n'), 'Grand mother');
    expect(normalizeRelationshipLabel('Mother'), 'Mother');
    expect(normalizeRelationshipLabel('   '), isNull);
    expect(normalizeRelationshipLabel(''), isNull);
    expect(normalizeRelationshipLabel(null), isNull);
  });

  test('validates the 50 character maximum after normalizing', () {
    expect(validateRelationshipLabel(null), isNull);
    expect(validateRelationshipLabel('Client'), isNull);
    expect(validateRelationshipLabel('a' * 50), isNull);
    expect(validateRelationshipLabel('a' * 51), isNotNull);
    // Extra spaces collapse, so this is 50 characters once normalized.
    expect(validateRelationshipLabel('${'a' * 25}      ${'b' * 24}'), isNull);
  });

  test('offers the standard suggestions and still allows custom text', () {
    expect(
      relationshipLabelSuggestions,
      containsAll([
        'Mother',
        'Father',
        'Grandmother',
        'Grandfather',
        'Spouse',
        'Relative',
        'Client',
        'Friend',
      ]),
    );
    expect(validateRelationshipLabel('Neighbour I look after'), isNull);
  });
}
