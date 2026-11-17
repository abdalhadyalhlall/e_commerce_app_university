class RegisterEntity {
  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;

  const RegisterEntity({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });
}
