import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class CryptoUtils {
  // Pre-shared 256-bit demo symmetric key for off-grid mesh encryption
  static const String _defaultKey = 'MeshLinkSecretKey2026AES32Bytes!';
  static const String _defaultIv = 'MeshLinkDemoIV16';

  /// Encrypt text using AES-256 (CBC)
  static String encryptPayload(String plainText, {String? customKey}) {
    try {
      final keyString = customKey ?? _defaultKey;
      final key = enc.Key.fromUtf8(keyString.padRight(32).substring(0, 32));
      final iv = enc.IV.fromUtf8(_defaultIv);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return encrypted.base64;
    } catch (e) {
      return plainText; // Fallback to raw if encryption fails
    }
  }

  /// Decrypt AES-256 ciphertext
  static String decryptPayload(String cipherBase64, {String? customKey}) {
    try {
      final keyString = customKey ?? _defaultKey;
      final key = enc.Key.fromUtf8(keyString.padRight(32).substring(0, 32));
      final iv = enc.IV.fromUtf8(_defaultIv);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(cipherBase64, iv: iv);
    } catch (e) {
      return cipherBase64;
    }
  }

  /// Calculate SHA-256 HMAC digest for packet integrity verification
  static String calculateHmac(String data) {
    final key = utf8.encode(_defaultKey);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  /// Verify HMAC signature
  static bool verifyHmac(String data, String signature) {
    final expectedHmac = calculateHmac(data);
    return expectedHmac == signature;
  }
}
