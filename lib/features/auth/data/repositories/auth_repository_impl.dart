import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/error_formatter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource_impl.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();

      return Right(user);
    } catch (e) {
      AppLogBuffer.instance.captureError('auth.getCurrentUser', e);
      return Left(ServerFailure(friendlyError(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final user = await remoteDataSource.signInWithEmail(email, password);

      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.signInWithEmail',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(_mapAuthError(e)));
    } catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.signInWithEmail',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(friendlyError(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      final user = await remoteDataSource.signUpWithEmail(email, password);

      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.signUpWithEmail',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(_mapAuthError(e)));
    } catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.signUpWithEmail',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(friendlyError(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final user = await remoteDataSource.signInWithGoogle();

      return Right(user);
    } on GoogleSignInException catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.signInWithGoogle (GoogleSignInException)',
        e,
      );
      return Left(
        ServerFailure('Google sign-in failed: ${e.description ?? e.code}'),
      );
    } catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.signInWithGoogle',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(friendlyError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();

      return const Right(null);
    } catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.signOut',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(friendlyError(e)));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await remoteDataSource.forgotPassword(email);

      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.forgotPassword',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(_mapAuthError(e)));
    } catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.forgotPassword',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(friendlyError(e)));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile(String displayName) async {
    try {
      final user = await remoteDataSource.updateProfile(displayName);

      return Right(user);
    } on fb.FirebaseAuthException catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.updateProfile',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(_mapAuthError(e)));
    } catch (e) {
      AppLogBuffer.instance.captureError(
        'auth.updateProfile',
        e,
        StackTrace.current,
      );
      return Left(ServerFailure(friendlyError(e)));
    }
  }

  String _mapAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
