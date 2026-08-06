import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../expense/domain/entities/expense_entity.dart';

abstract class SyncRepository {
  Future<Either<Failure, void>> pushPendingChanges();
  Future<Either<Failure, void>> pullRemoteChanges();
  Stream<List<ExpenseEntity>> watchRemoteExpenses();
}
