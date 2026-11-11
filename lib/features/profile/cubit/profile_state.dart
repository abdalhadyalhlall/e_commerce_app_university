part of 'profile_cubit.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileError extends ProfileState {
  final String message;
  ProfileError({required this.message});
}

final class ProfileSuccess extends ProfileState {}

final class ProfileImagePickedSuccess extends ProfileState {
  final File imagePath;
  ProfileImagePickedSuccess({required this.imagePath});
}
