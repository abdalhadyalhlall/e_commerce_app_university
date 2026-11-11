import 'package:chat_with_firbase/features/auth/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: ScreenUtilInit(
        child: MaterialApp(
          title: 'chat',
          theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
          // home:
        ),
      ),
    );
  }
}
