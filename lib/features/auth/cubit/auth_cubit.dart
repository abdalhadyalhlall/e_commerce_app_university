import 'package:bloc/bloc.dart';
import 'package:chat_with_firbase/core/helpers/cach_helper.dart';
import 'package:chat_with_firbase/features/auth/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:meta/meta.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  late final FirebaseAuth auth = FirebaseAuth.instance;

  String firbaseErrorMessage(String message) {
    switch (message) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'account-exists-with-different-credential':
        return 'This email is already used with another login method.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Future<void> saveUserData(UserModel user) async {
   try { 
      String searchName = user.name.toLowerCase();
      Map <String, dynamic> userJson = user.toMap();
      userJson['searchname'] = searchName;

      await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(userJson, SetOptions(merge: true));
        } catch (e) {
      print(e);
    }
  }

  Future<void> addMissingSearchName(DocumentSnapshot snapshot) async {
    try{

      final data = snapshot.data() as Map<String, dynamic>?;
      if(data!['searchName'] != null) {
        return; // searchName already exists, no need to add
      }

      final String name = data['name'] as String? ?? '';

      await snapshot.reference.update({'searchName': name.toLowerCase().trim()});

    }catch(e){
      print('Error adding search name: $e');
    }
  }


  Future<void> rigesterWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    emit(AuthLoading());
    try {
      final UserCredential credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if(user == null) {
        emit(AuthError(message: 'User creation failed.'));
        return;
      }

      user.updateDisplayName(name.trim());
      user.sendEmailVerification();

        final newUser = UserModel(
          email: email,
          password: password,
          name: name,
          uid: user.uid,
        );

        
        await saveUserData(newUser);
        emit(AuthSuccess(user: newUser));
      
    } on FirebaseAuthException catch (e) {
      final errorMessage = firbaseErrorMessage(e.code);
      emit(AuthError(message: errorMessage));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred.'));
    }
  }

  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      final UserCredential credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;

      if(user == null) {
        emit(AuthError(message: 'Login failed.'));
        return;
      }

      await user.reload(); 

      if(!user.emailVerified) {
        emit(AuthError(message: 'Please verify your email.'));
        return;
      }

      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userData.exists) {
        emit(AuthError(message: 'User data not found.'));
        return;
      }
      final userModel = UserModel.fromMap(userData.data()!);

      CacheHelper.saveUserModelData(
        userModel: userModel,
        userKey: "user",
      );

      emit(AuthSuccess(user: userModel));
    } on FirebaseAuthException catch (e) {
      final errorMessage = firbaseErrorMessage(e.code);
      emit(AuthError(message: errorMessage));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred.'));
    }

}

    bool isGoogleSignInInitialized = false;

    Future<void> initializeGoogleSignIn() async {
      if(isGoogleSignInInitialized) return;

      await GoogleSignIn.instance.initialize();
      isGoogleSignInInitialized = true;
      
    }

    Future<UserModel> getOrCreateGoogleUser(User user) async {
      final DocumentReference userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final DocumentSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
      }

      final userModel=  UserModel(
        email: user.email ?? '',
        password: '',
        name: user.displayName ?? '',
        uid: user.uid,
        imageUrl: user.photoURL,
      );

      String searchName = userModel.name.toLowerCase();
      Map <String, dynamic> userJson = userModel.toMap();
      userJson['searchname'] = searchName;

      await userRef.set(userJson);
      
      return userModel;
    }

    Future<void> loginWithGoogle() async {
     try {
      await initializeGoogleSignIn();

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if(user == null) {
        emit(AuthError(message: 'Login failed.'));
        return;
      }

      final UserModel userModel = await getOrCreateGoogleUser(user);

      await CacheHelper.saveUserModelData(
        userModel: userModel,
        userKey: "user",
      );

      emit(AuthSuccess(user: userModel));
      

      } on FirebaseAuthException catch (e) {
        final errorMessage = firbaseErrorMessage(e.code);
        emit(AuthError(message: errorMessage));
      } catch (e) {
        emit(AuthError(message: 'An unexpected error occurred.'));
      }

    }

    Future<void> signOut() async {
     try{
      emit(AuthLoading());

      await GoogleSignIn.instance.signOut();

      await auth.signOut();

      await CacheHelper.removeUserModelData();

      emit(AuthInitial());
     } on FirebaseAuthException catch (e) {
        final errorMessage = firbaseErrorMessage(e.code);
        emit(AuthError(message: errorMessage));
      } catch (e) {
        emit(AuthError(message: 'An unexpected error occurred.'));

     }
    }




}