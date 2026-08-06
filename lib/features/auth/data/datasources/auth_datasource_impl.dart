import 'package:expense_flow_app/features/auth/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithEmail(String email, String password);

  Future<UserModel> signUpWithEmail(String email, String password);

  Future<UserModel> signInWithGoogle();

  Future<void> signOut();

  Future<void> forgotPassword(String email);

  Future<UserModel> updateProfile(String displayName);
}

class AuthDataSourceImpl implements AuthDataSource {
  final fb.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthDataSourceImpl({required this.firebaseAuth, required this.googleSignIn});

  @override
  Future<UserModel?> getCurrentUser() {
    final user = firebaseAuth.currentUser;
    return Future.value(user == null ? null : UserModel.fromFirebaseUser(user));
  }

  @override
  Future<UserModel> signInWithEmail(String email, String password) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return UserModel.fromFirebaseUser(credential.user!);
  }

  @override
  Future<UserModel> signUpWithEmail(String email, String password) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    return UserModel.fromFirebaseUser(credential.user!);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    final account = await googleSignIn.authenticate();

    final auth = account.authentication;

    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

    final userCredential = await firebaseAuth.signInWithCredential(credential);

    return UserModel.fromFirebaseUser(userCredential.user!);
  }

  @override
  Future<void> forgotPassword(String email) {
    return firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await googleSignIn.signOut();
  }

  @override
  Future<UserModel> updateProfile(String displayName) async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw fb.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user',
      );
    }

    await user.updateDisplayName(displayName);
    await user.reload();

    final refreshed = firebaseAuth.currentUser;
    if (refreshed == null) {
      throw fb.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user',
      );
    }

    return UserModel.fromFirebaseUser(refreshed);
  }
}
