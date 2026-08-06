import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/budget_entity.dart';

abstract class BudgetSyncRepository {
  Future<Either<Failure, void>> pushPendingChanges();
  Future<Either<Failure, void>> pullRemoteChanges();
  Stream<List<BudgetEntity>> watchRemoteBudgets();
}
