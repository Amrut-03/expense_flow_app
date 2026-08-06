import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/budget_sync_repository.dart';

class PushBudgetChangesUseCase {
  final BudgetSyncRepository repository;

  PushBudgetChangesUseCase(this.repository);

  Future<Either<Failure, void>> call() => repository.pushPendingChanges();
}
