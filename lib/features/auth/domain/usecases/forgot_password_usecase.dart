import 'package:dartz/dartz.dart';
import 'package:expense_flow_app/core/error/failures.dart';
import 'package:expense_flow_app/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository authRepository;
  const ForgotPasswordUseCase(this.authRepository);

  Future<Either<Failure, void>> call(String email) async {
    return await authRepository.forgotPassword(email);
  }
}
