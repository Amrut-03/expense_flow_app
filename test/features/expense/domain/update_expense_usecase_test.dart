import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/domain/usecases/update_expense_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_expense_repository.dart';

void main() {
  final created = DateTime(2026, 10, 1);
  final now = DateTime(2026, 11, 7);

  ExpenseEntity expense({double amount = 100, String? merchant}) {
    return ExpenseEntity(
      id: 'e1',
      amount: amount,
      currency: 'INR',
      categoryId: 'food',
      merchant: merchant,
      date: created,
      createdAt: created,
      updatedAt: created,
      version: 3,
      syncStatus: SyncStatus.synced,
    );
  }

  group('UpdateExpenseUseCase', () {
    test('bumps version, marks pending and stamps updatedAt', () async {
      final repository = InMemoryExpenseRepository();
      final useCase = UpdateExpenseUseCase(repository, now: () => now);

      await useCase(expense(merchant: 'D-Mart'));

      final saved = repository.byId['e1']!;
      expect(saved.version, 4);
      expect(saved.syncStatus, SyncStatus.pending);
      expect(saved.updatedAt, now);
      expect(saved.createdAt, created);
      expect(saved.merchant, 'D-Mart');
    });

    test('rejects an invalid amount without saving', () async {
      final repository = InMemoryExpenseRepository();
      final useCase = UpdateExpenseUseCase(repository, now: () => now);

      await expectLater(useCase(expense(amount: 0)), throwsA(isA<Exception>()));
      expect(repository.byId, isEmpty);
    });
  });
}
