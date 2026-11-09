import 'package:expense_flow_app/features/expense/data/models/expense_model.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 11, 7, 9, 15);

  ExpenseEntity entity() {
    return ExpenseEntity(
      id: 'e1',
      amount: 4166.5,
      currency: 'USD',
      categoryId: 'travel',
      title: 'Flight',
      merchant: 'IndiGo',
      originalAmount: 50,
      exchangeRate: 83.33,
      recurringId: 'r1',
      paymentMethod: 'Card',
      date: date,
      createdAt: date,
      updatedAt: date,
      version: 2,
      syncStatus: SyncStatus.synced,
    );
  }

  group('ExpenseModel', () {
    test('entity -> model -> entity is lossless', () {
      expect(ExpenseModel.fromEntity(entity()).toEntity(), entity());
    });

    test('JSON round trip keeps the new fields', () {
      final json = ExpenseModel.fromEntity(entity()).toJson();

      expect(json['merchant'], 'IndiGo');
      expect(json['originalAmount'], 50);
      expect(json['exchangeRate'], 83.33);
      expect(json['recurringId'], 'r1');
      expect(ExpenseModel.fromJson(json).toEntity(), entity());
    });

    test('reads legacy records that predate the new fields', () {
      final legacy = {
        'id': 'old',
        'amount': 120,
        'currency': 'INR',
        'categoryId': 'food',
        'title': 'Chai',
        'date': date.toIso8601String(),
        'createdAt': date.toIso8601String(),
        'updatedAt': date.toIso8601String(),
      };

      final restored = ExpenseModel.fromJson(legacy).toEntity();

      expect(restored.merchant, isNull);
      expect(restored.originalAmount, isNull);
      expect(restored.exchangeRate, isNull);
      expect(restored.recurringId, isNull);
      expect(restored.amount, 120);
      expect(restored.version, 1);
      expect(restored.syncStatus, SyncStatus.pending);
    });
  });

  group('ExpenseEntity helpers', () {
    test('paidAmount falls back to the INR amount for legacy records', () {
      final legacy = entity().copyWith();
      final noOriginal = ExpenseEntity(
        id: legacy.id,
        amount: 300,
        currency: 'INR',
        categoryId: 'food',
        date: date,
        createdAt: date,
        updatedAt: date,
      );

      expect(legacy.paidAmount, 50);
      expect(noOriginal.paidAmount, 300);
    });

    test('isForeignCurrency only for non-INR with a recorded original', () {
      expect(entity().isForeignCurrency, isTrue);
      expect(
        ExpenseEntity(
          id: 'x',
          amount: 10,
          currency: 'INR',
          originalAmount: 10,
          categoryId: 'food',
          date: date,
          createdAt: date,
          updatedAt: date,
        ).isForeignCurrency,
        isFalse,
      );
    });
  });
}
