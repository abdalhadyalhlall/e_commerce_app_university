import 'dart:convert';

import 'package:chat_with_firbase/features/auth/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;

  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<void> saveUserModelData (
    {
      required UserModel userModel,
      required String userKey,
    }
  )async{
    final userModelJson = jsonEncode(userModel.toMap());

    await sharedPreferences.setString(userKey, userModelJson);

  }

  static UserModel? getUserModelData({required String userKey}) {
    final userModelJson = sharedPreferences.getString(userKey);

    if (userModelJson == null) {
      return null;
    }
    final userModelMap = jsonDecode(userModelJson);
    return UserModel.fromMap(userModelMap);
  }

  static Future<void> removeUserModelData() async {
    await sharedPreferences.clear();
  }
}