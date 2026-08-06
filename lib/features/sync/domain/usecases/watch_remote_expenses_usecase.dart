import '../../../expense/domain/entities/expense_entity.dart';
import '../repositories/sync_repository.dart';

class WatchRemoteExpensesUseCase {
  final SyncRepository repository;

  const WatchRemoteExpensesUseCase(this.repository);

  Stream<List<ExpenseEntity>> call() => repository.watchRemoteExpenses();
}
