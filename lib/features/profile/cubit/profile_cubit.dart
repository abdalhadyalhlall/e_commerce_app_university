import 'dart:io';

import 'package:chat_with_firbase/core/helpers/cach_helper.dart';
import 'package:chat_with_firbase/features/auth/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  late final FirebaseAuth auth = FirebaseAuth.instance;
  late final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker imagePicker = ImagePicker();

  static const profileImageBucket = 'chat_profile_image';

  File? selectedProfileImage;

  Future<void> pickProfileImage() async {
    try {
      final XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
       return; // User canceled the picker
      }

       selectedProfileImage = File(pickedFile.path);
        emit(ProfileImagePickedSuccess(imagePath: selectedProfileImage!));
    } catch (e) {
      emit(ProfileError(message: 'Failed to pick image: $e'));
    }
  }


  Future<String> uploadprofileImageAndGetUrl({required File imageFile})async{
    final User? user = auth.currentUser;

    if(user == null) {
      emit(ProfileError(message: 'User not authenticated.'));
      return ''; 
    }

    final String imagepath = 'users/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage
         .from(profileImageBucket)
         .upload(
          imagepath,
          imageFile,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: 'image/jpeg',
          ),
          );

    String imageUrl = supabase.storage.from(profileImageBucket).getPublicUrl(imagepath);
    // Return the URL of the uploaded image
    return imageUrl;
  }

  Future<void> updateProfileImage(
    {
      required String name,
      required File? imageFile,
    }) async {
    try {
      emit(ProfileLoading());
      
    final User? user = auth.currentUser;

    if(user == null) {
      emit(ProfileError(message: 'User not authenticated.'));
      return; 
    }
     final DocumentReference<Map<String, dynamic>> userDocRef = firestore.collection('users').doc(user.uid);

     final Map<String, dynamic> updateData = {};

     if(name.trim().isNotEmpty) {
      updateData['name'] = name.trim();
     }

      if(imageFile != null) {
          final String imageUrl = await uploadprofileImageAndGetUrl(imageFile: imageFile);
          updateData['imageUrl'] = imageUrl;
      }

      if(updateData.isEmpty) {
        emit(ProfileError(message: 'No data to update.'));
        return;
      }

      await userDocRef.update(updateData);

      if(updateData.containsKey('name')) {
        await user.updateDisplayName(updateData['name']);
      }

      if(updateData.containsKey('imageUrl')) {
        await user.updatePhotoURL(updateData['imageUrl']);
      }

      final DocumentSnapshot<Map<String, dynamic>> userDoc = await userDocRef.get();

      final Map<String, dynamic>? userData = userDoc.data();


      if(userData == null) {
        emit(ProfileError(message: 'Failed to fetch updated user data.'));
        return;
      }

      final UserModel updatedUser = UserModel.fromMap(userData);

      await CacheHelper.saveUserModelData(
        userModel: updatedUser, 
        userKey: 'user'
      );

      emit(ProfileSuccess());
    }on StorageException catch (e) {
      emit(ProfileError(message: 'Failed to update profile image: $e'));
    }on FirebaseException catch (e) {
      emit(ProfileError(message: 'Failed to update profile: ${e.message}'));
    } catch (e) {
      emit(ProfileError(message: 'An unexpected error occurred: $e'));
    }
  }
}
