import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  group('PIN Hashing & Security Tests', () {
    test('Hash PIN dengan salt menghasilkan hash yang konsisten', () {
      const pin = '123456';
      const salt = 'random_salt_123';

      final bytes1 = utf8.encode(pin + salt);
      final hash1 = sha256.convert(bytes1).toString();

      final bytes2 = utf8.encode(pin + salt);
      final hash2 = sha256.convert(bytes2).toString();

      expect(hash1, equals(hash2));
      expect(hash1, isNot(equals(pin)));
    });

    test('PIN yang salah menghasilkan hash berbeda', () {
      const pinCorrect = '123456';
      const pinWrong = '654321';
      const salt = 'random_salt_123';

      final hash1 = sha256.convert(utf8.encode(pinCorrect + salt)).toString();
      final hash2 = sha256.convert(utf8.encode(pinWrong + salt)).toString();

      expect(hash1, isNot(equals(hash2)));
    });
  });
}
