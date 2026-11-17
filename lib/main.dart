import 'package:clean_arch_session/core/cache/cache_const.dart';
import 'package:clean_arch_session/core/cache/cache_helper.dart';
import 'package:clean_arch_session/core/di/dependency_injection.dart';
import 'package:clean_arch_session/core/routes/routes.dart';
import 'package:clean_arch_session/e_commerce.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupGetIt();
  final token = await CacheHelper.getSecureData(key: CacheConstants.userToken);
  runApp(MyApp(initialRoute: token == null ? Routes.login : Routes.store));
}
