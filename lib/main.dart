import 'package:chat_with_firbase/chat.dart';
import 'package:chat_with_firbase/core/helpers/cach_helper.dart';
import 'package:chat_with_firbase/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await CacheHelper.init();

  await Supabase.initialize(
    url: 'https://froqugachdtrtsmgpduk.supabase.co',
    publishableKey: 'sb_publishable_ohOvCwx86_PcYGFJDEOr-A_4v_MDgPz',
  );

  runApp(const MyApp());
}
