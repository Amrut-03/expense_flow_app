import '../../domain/entities/budget_entity.dart';
import '../repositories/budget_sync_repository.dart';

class WatchRemoteBudgetsUseCase {
  final BudgetSyncRepository repository;

  WatchRemoteBudgetsUseCase(this.repository);

  Stream<List<BudgetEntity>> call() => repository.watchRemoteBudgets();
}
