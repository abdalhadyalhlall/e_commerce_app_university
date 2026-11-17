import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheHelper {

  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
//save data in secure storage
  static Future<void> saveSecureData({
    required String key,
    required String value,
  }) async {
    await _secureStorage.write(key: key, value: value);
  }

//get data from secure storage
  static Future<String?> getSecureData({required String key}) async {
    return await _secureStorage.read(key: key);
  }
//delete data from secure storage
  static Future<void> deleteSecureData({required String key}) async {
    await _secureStorage.delete(key: key);
  }
}
