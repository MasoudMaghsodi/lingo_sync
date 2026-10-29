import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_sync/core/utils/uuid_generator.dart';

void main() {
  group('UuidGenerator Tests', () {
    test('generates valid RFC 4122 v4 UUID format', () {
      final uuid = UuidGenerator.v4();
      expect(uuid.length, equals(36));
      expect(UuidGenerator.isValidV4(uuid), isTrue);

      // Check version bit (index 14 should be '4')
      expect(uuid[14], equals('4'));
      // Check variant bit (index 19 should be '8', '9', 'a', or 'b')
      expect(['8', '9', 'a', 'b'].contains(uuid[19].toLowerCase()), isTrue);
    });

    test('generates unique UUIDs on subsequent calls', () {
      final set = <String>{};
      for (var i = 0; i < 1000; i++) {
        final id = UuidGenerator.v4();
        expect(set.contains(id), isFalse, reason: 'Duplicate UUID generated');
        set.add(id);
      }
      expect(set.length, equals(1000));
    });

    test('validates incorrect UUID strings correctly', () {
      expect(UuidGenerator.isValidV4(null), isFalse);
      expect(UuidGenerator.isValidV4(''), isFalse);
      expect(UuidGenerator.isValidV4('12345'), isFalse);
      // Non-v4 (version bit is 1 instead of 4)
      expect(
        UuidGenerator.isValidV4('123e4567-e89b-12d3-a456-426614174000'),
        isFalse,
      );
    });
  });
}
