import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores sensitive credentials in the device's native secure enclave:
///   • Windows  → Credential Manager
///   • Android  → EncryptedSharedPreferences (AES-256)
///   • iOS/macOS → Keychain
///
/// Never write secrets to SharedPreferences, files, or Dart source code.
class SecureStorageService {
  static const _geminiKeyField = 'gemini_api_key';

  static const _storage = FlutterSecureStorage(
    // Android: use EncryptedSharedPreferences backed by the Android Keystore.
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    // iOS/macOS: store in the Keychain, accessible only when device is unlocked.
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  /// Returns the stored Gemini API key, or null if none has been saved yet.
  Future<String?> readGeminiApiKey() async {
    return await _storage.read(key: _geminiKeyField);
  }

  /// Saves [key] to the secure store, overwriting any previous value.
  Future<void> writeGeminiApiKey(String key) async {
    await _storage.write(key: _geminiKeyField, value: key);
  }

  /// Removes the stored key (e.g. when the user clears credentials).
  Future<void> deleteGeminiApiKey() async {
    await _storage.delete(key: _geminiKeyField);
  }
}
