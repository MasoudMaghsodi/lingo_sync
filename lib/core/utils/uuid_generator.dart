import 'dart:math';

/// Pure Dart RFC 4122 Version 4 UUID Generator.
/// Generates cryptographically secure, standard UUIDv4 strings
/// without requiring external packages.
abstract final class UuidGenerator {
  static final Random _secureRandom = Random.secure();

  /// Generates a standard 36-character canonical UUIDv4 string:
  /// xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  static String v4() {
    final values = List<int>.generate(16, (_) => _secureRandom.nextInt(256));

    // Set version to 4 -> bits 12-15 of time_hi_and_version
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122 -> bits 6-7 of clock_seq_hi_and_reserved to 10
    values[8] = (values[8] & 0x3f) | 0x80;

    return '${_toHex(values.sublist(0, 4))}-'
        '${_toHex(values.sublist(4, 6))}-'
        '${_toHex(values.sublist(6, 8))}-'
        '${_toHex(values.sublist(8, 10))}-'
        '${_toHex(values.sublist(10, 16))}';
  }

  static String _toHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Validates whether a given string is a valid UUIDv4 format.
  static bool isValidV4(String? uuid) {
    if (uuid == null || uuid.length != 36) return false;
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return regex.hasMatch(uuid);
  }
}
