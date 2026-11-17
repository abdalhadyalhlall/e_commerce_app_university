import 'package:clean_arch_session/core/routes/routes.dart';
import 'package:clean_arch_session/core/widgets/app_button.dart';
import 'package:clean_arch_session/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F6),
        body: SafeArea(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.store,
                  (route) => false,
                );
              } else if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F1EC),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            color: Color(0xFF176B5B),
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'أهلاً بعودتك',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: const Color(0xFF172B4D),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'سجّل دخولك وتابع تسوّقك بسهولة.',
                          style: TextStyle(color: Color(0xFF718079)),
                        ),
                        const SizedBox(height: 28),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  labelText: 'البريد الإلكتروني',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty ||
                                      !email.contains('@') ||
                                      !email.contains('.')) {
                                    return 'أدخل بريداً إلكترونياً صحيحاً';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                ),
                                validator: (value) => (value?.isEmpty ?? true)
                                    ? 'أدخل كلمة المرور'
                                    : null,
                                onFieldSubmitted: (_) => _login(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'تسجيل الدخول',
                          isLoading: state is AuthLoading,
                          onPressed: _login,
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () => Navigator.pushNamed(
                                  context,
                                  Routes.register,
                                ),
                          child: const Text('ليس لديك حساب؟ أنشئ حساباً جديداً'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
