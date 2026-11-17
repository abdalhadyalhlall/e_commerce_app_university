import 'package:clean_arch_session/core/routes/routes.dart';
import 'package:clean_arch_session/core/widgets/app_button.dart';
import 'package:clean_arch_session/feature/auth/domain/entities/register_entity.dart';
import 'package:clean_arch_session/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().register(
      RegisterEntity(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmationController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7F6),
          title: const Text('إنشاء حساب'),
        ),
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
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'ابدأ رحلتك معنا',
                            style: TextStyle(
                              color: Color(0xFF172B4D),
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'أنشئ حسابك لتستمتع بتجربة تسوّق أسهل.',
                            style: TextStyle(color: Color(0xFF718079)),
                          ),
                          const SizedBox(height: 26),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'الاسم',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) =>
                                (value?.trim().isEmpty ?? true)
                                ? 'أدخل الاسم'
                                : null,
                          ),
                          const SizedBox(height: 15),
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
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            validator: (value) => (value?.length ?? 0) < 6
                                ? 'كلمة المرور يجب ألا تقل عن 6 أحرف'
                                : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _confirmationController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'تأكيد كلمة المرور',
                              prefixIcon: Icon(Icons.lock_reset_rounded),
                            ),
                            validator: (value) =>
                                value != _passwordController.text
                                ? 'كلمتا المرور غير متطابقتين'
                                : null,
                            onFieldSubmitted: (_) => _register(),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: 'إنشاء الحساب',
                            isLoading: state is AuthLoading,
                            onPressed: _register,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: state is AuthLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('لديك حساب؟ سجّل الدخول'),
                          ),
                        ],
                      ),
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
