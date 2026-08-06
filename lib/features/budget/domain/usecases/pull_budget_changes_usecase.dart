import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/budget_sync_repository.dart';

class PullBudgetChangesUseCase {
  final BudgetSyncRepository repository;

  PullBudgetChangesUseCase(this.repository);

  Future<Either<Failure, void>> call() => repository.pullRemoteChanges();
}
