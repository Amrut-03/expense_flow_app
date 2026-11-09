import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/domain/repositories/expense_repository.dart';
import 'package:expense_flow_app/features/expense/domain/usecases/add_expense_usecase.dart';
import 'package:expense_flow_app/features/groups/domain/entities/group.dart';
import 'package:expense_flow_app/features/groups/domain/repositories/group_repository.dart';
import 'package:expense_flow_app/features/groups/domain/services/split_math.dart';
import 'package:expense_flow_app/features/groups/domain/usecases/group_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

class _FakeGroupExpense extends Fake implements GroupExpense {}

class _FakeSettlement extends Fake implements GroupSettlement {}

class _FakeExpense extends Fake implements ExpenseEntity {}

GroupExpense _expense(
  String paidBy,
  double amount,
  Map<String, double> shares, {
  DateTime? date,
}) => GroupExpense(
  id: '$paidBy$amount',
  title: 't',
  amount: amount,
  paidBy: paidBy,
  shares: shares,
  date: date ?? DateTime(2026, 11, 5),
  createdBy: paidBy,
  createdAt: DateTime(2026, 11, 5),
);

void main() {
  final flat = SpendingGroup(
    id: 'g1',
    name: 'Flat 302',
    kind: GroupKind.roommates,
    ownerUid: 'a',
    members: const [
      GroupMember(uid: 'a', name: 'Asha'),
      GroupMember(uid: 'b', name: 'Bilal'),
      GroupMember(uid: 'c', name: 'Chetan'),
    ],
    createdAt: DateTime(2026, 11),
  );

  group('SplitMath', () {
    test('equal split hands leftover paise to the first members', () {
      final shares = SplitMath.equal(100, ['a', 'b', 'c']);
      expect(shares, {'a': 33.34, 'b': 33.33, 'c': 33.33});
      expect(SplitMath.sharesMatch(100, shares), isTrue);
    });

    test('sharesMatch is exact to the paisa and rejects negatives', () {
      expect(SplitMath.sharesMatch(10, {'a': 3.33, 'b': 6.67}), isTrue);
      expect(SplitMath.sharesMatch(10, {'a': 3.33, 'b': 6.66}), isFalse);
      expect(SplitMath.sharesMatch(10, {'a': 12, 'b': -2}), isFalse);
    });

    test('balances net expenses and settlements, summing to zero', () {
      final balances = SplitMath.balances(
        members: ['a', 'b', 'c'],
        expenses: [
          _expense('a', 300, SplitMath.equal(300, ['a', 'b', 'c'])),
          _expense('b', 90, {'b': 45, 'c': 45}),
        ],
        settlements: [
          GroupSettlement(
            id: 's',
            from: 'c',
            to: 'a',
            amount: 50,
            date: DateTime(2026, 11, 6),
            createdBy: 'c',
          ),
        ],
      );
      expect(balances, {'a': 150.0, 'b': -55.0, 'c': -95.0});
      expect(
        balances.values.fold<int>(0, (s, v) => s + SplitMath.toPaise(v)),
        0,
      );
    });

    test('settleUp clears every balance in at most n-1 transfers', () {
      final balances = {'a': 150.0, 'b': -55.0, 'c': -95.0, 'd': 0.0};
      final transfers = SplitMath.settleUp(balances);
      expect(transfers.length, lessThanOrEqualTo(3));
      final after = {...balances};
      for (final t in transfers) {
        after[t.from] = after[t.from]! + t.amount;
        after[t.to] = after[t.to]! - t.amount;
      }
      for (final v in after.values) {
        expect(SplitMath.toPaise(v), 0);
      }
      expect(transfers, contains(const Transfer('c', 'a', 95)));
    });

    test('spentThisMonth only counts the current calendar month', () {
      final spent = SplitMath.spentThisMonth([
        _expense('a', 100, {'a': 100}, date: DateTime(2026, 11, 2)),
        _expense('a', 40, {'a': 40}, date: DateTime(2026, 10, 30)),
      ], DateTime(2026, 11, 9));
      expect(spent, 100);
    });
  });

  group('use cases', () {
    late _MockGroupRepository repo;
    late _MockExpenseRepository expenses;

    setUpAll(() {
      registerFallbackValue(_FakeGroupExpense());
      registerFallbackValue(_FakeSettlement());
      registerFallbackValue(_FakeExpense());
    });

    setUp(() {
      repo = _MockGroupRepository();
      expenses = _MockExpenseRepository();
      when(() => repo.currentUid).thenReturn('a');
      when(() => repo.addExpense(any(), any())).thenAnswer((_) async {});
      when(() => repo.addSettlement(any(), any())).thenAnswer((_) async {});
      when(() => repo.leave(any())).thenAnswer((_) async {});
      when(() => expenses.addExpense(any())).thenAnswer((_) async {});
    });

    AddGroupExpenseUseCase addUseCase() => AddGroupExpenseUseCase(
      repo,
      addPersonalExpense: AddExpenseUseCase(expenses),
      now: () => DateTime(2026, 11, 9, 12),
      newId: () => 'e1',
    );

    test('adds the expense and logs my share as a personal expense', () async {
      final error = await addUseCase()(
        group: flat,
        title: ' Groceries ',
        amount: 300,
        paidBy: 'b',
        shares: SplitMath.equal(300, flat.memberUids),
        categoryId: 'groceries',
        addMyShareToMyExpenses: true,
      );
      expect(error, isNull);
      final saved =
          verify(() => repo.addExpense('g1', captureAny())).captured.single
              as GroupExpense;
      expect(saved.title, 'Groceries');
      expect(saved.createdBy, 'a');
      final personal =
          verify(() => expenses.addExpense(captureAny())).captured.single
              as ExpenseEntity;
      expect(personal.amount, 100);
      expect(personal.categoryId, 'groceries');
    });

    test('rejects shares that do not add up, or include outsiders', () async {
      expect(
        await addUseCase()(
          group: flat,
          title: 'Rent',
          amount: 100,
          paidBy: 'a',
          shares: {'a': 50, 'b': 40},
        ),
        GroupExpenseError.shares,
      );
      expect(
        await addUseCase()(
          group: flat,
          title: 'Rent',
          amount: 100,
          paidBy: 'a',
          shares: {'a': 50, 'zz': 50},
        ),
        GroupExpenseError.shares,
      );
      expect(
        await addUseCase()(
          group: flat,
          title: 'Rent',
          amount: 100,
          paidBy: 'zz',
          shares: {'a': 100},
        ),
        GroupExpenseError.payer,
      );
      verifyNever(() => repo.addExpense(any(), any()));
    });

    test('settlement must be between two different members', () async {
      final useCase = RecordSettlementUseCase(repo, newId: () => 's1');
      expect(
        await useCase(group: flat, from: 'a', to: 'a', amount: 10),
        SettlementError.people,
      );
      expect(
        await useCase(group: flat, from: 'b', to: 'a', amount: 0.001),
        SettlementError.amount,
      );
      expect(
        await useCase(group: flat, from: 'b', to: 'a', amount: 10.004),
        isNull,
      );
      final s =
          verify(() => repo.addSettlement('g1', captureAny())).captured.single
              as GroupSettlement;
      expect(s.amount, 10.0);
    });

    test('leaving needs a settled balance; the owner leaves last', () async {
      final useCase = LeaveGroupUseCase(repo);
      expect(
        await useCase(group: flat, balances: {'a': 20}),
        LeaveGroupError.unsettled,
      );
      expect(
        await useCase(group: flat, balances: {'a': 0}),
        LeaveGroupError.ownerWithMembers,
      );
      when(() => repo.currentUid).thenReturn('b');
      expect(await useCase(group: flat, balances: {'b': 0}), isNull);
      verify(() => repo.leave('g1')).called(1);
    });
  });
}
