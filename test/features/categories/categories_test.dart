import 'dart:async';

import 'package:expense_flow_app/core/constants/category_label.dart';
import 'package:expense_flow_app/core/constants/custom_category_registry.dart';
import 'package:expense_flow_app/core/constants/expense_category.dart';
import 'package:expense_flow_app/core/theme/app_colors.dart';
import 'package:expense_flow_app/features/categories/domain/entities/custom_category.dart';
import 'package:expense_flow_app/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_flow_app/features/categories/domain/services/category_suggester.dart';
import 'package:expense_flow_app/features/categories/domain/usecases/custom_category_usecases.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';

class _MemoryCategoryRepository implements CategoryRepository {
  final Map<String, CustomCategory> byId = {};

  @override
  Future<void> initialize() async =>
      CustomCategoryRegistry.replaceAll(byId.values);

  @override
  List<CustomCategory> getAll() => byId.values.toList();

  @override
  Future<void> save(CustomCategory category) async {
    byId[category.id] = category;
    CustomCategoryRegistry.replaceAll(byId.values);
  }

  @override
  Future<void> pullRemote() async {}

  @override
  Stream<void> watch() => const Stream.empty();
}

void main() {
  final now = DateTime(2026, 11, 7);
  late _MemoryCategoryRepository repo;
  var ids = 0;

  CreateCustomCategoryUseCase create() => CreateCustomCategoryUseCase(
    repo,
    now: () => now,
    newId: () => 'c${++ids}',
  );

  setUp(() {
    repo = _MemoryCategoryRepository();
    CustomCategoryRegistry.replaceAll(const []);
  });

  tearDown(() => CustomCategoryRegistry.replaceAll(const []));

  group('custom category use cases', () {
    test('creates a category and exposes it through the registry', () async {
      final rent = await create()(
        label: '  Rent ',
        emoji: '🏠',
        colorValue: 0xFF5E35B1,
      );

      expect(rent.label, 'Rent');
      expect(ExpenseCategories.all.map((c) => c.id), contains(rent.id));
      expect(ExpenseCategories.byId(rent.id).label, 'Rent');
      expect(ExpenseCategories.byId(rent.id).isCustom, isTrue);
      expect(CategoryLabels.labelOf(rent.id), 'Rent');
      expect(
        ExpenseCategories.colorFor(NeuPalette.light, rent.id),
        const Color(0xFF5E35B1),
      );
    });

    test('rejects empty, too long and duplicate names', () async {
      Future<void> expectError(String label, CategoryValidationError error) =>
          expectLater(
            create()(label: label, emoji: '🏷️', colorValue: 0),
            throwsA(
              isA<CategoryValidationException>().having(
                (e) => e.reason,
                'reason',
                error,
              ),
            ),
          );

      await expectError('   ', CategoryValidationError.emptyName);
      await expectError('x' * 25, CategoryValidationError.nameTooLong);
      await expectError('food', CategoryValidationError.duplicateName);

      await create()(label: 'Rent', emoji: '🏠', colorValue: 0);
      await expectError('RENT', CategoryValidationError.duplicateName);
    });

    test('archiving hides from pickers but keeps the label', () async {
      final kirana = await create()(
        label: 'Kirana',
        emoji: '🛒',
        colorValue: 0,
      );
      await ArchiveCustomCategoryUseCase(repo, now: () => now)(kirana);

      expect(
        ExpenseCategories.all.map((c) => c.id),
        isNot(contains(kirana.id)),
      );
      expect(ExpenseCategories.byId(kirana.id).label, 'Kirana');

      // The name is free to reuse once archived.
      await create()(label: 'Kirana', emoji: '🛒', colorValue: 0);
    });

    test('unknown ids still fall back to Other', () {
      expect(ExpenseCategories.byId('nope').id, 'other');
      expect(
        ExpenseCategories.colorFor(NeuPalette.light, 'nope'),
        NeuPalette.light.textMuted,
      );
    });
  });

  group('CategorySuggester', () {
    final history = [
      expenseOf(amount: 300, date: now, merchant: 'Swiggy', categoryId: 'food'),
      expenseOf(amount: 250, date: now, merchant: 'SWIGGY', categoryId: 'food'),
      expenseOf(
        amount: 99,
        date: now,
        merchant: 'Swiggy',
        categoryId: 'shopping',
      ),
      expenseOf(
        amount: 800,
        date: now,
        merchant: 'Ramesh Kirana',
        categoryId: 'c_kirana',
      ),
    ];

    test('prefers the user\'s own most frequent category', () {
      final s = CategorySuggester.suggest(
        merchant: 'swiggy',
        history: history,
      )!;
      expect(s.categoryId, 'food');
      expect(s.source, SuggestionSource.history);
    });

    test('matches on a shared distinctive word', () {
      final s = CategorySuggester.suggest(
        merchant: 'Swiggy Instamart',
        history: history,
      )!;
      expect(s.categoryId, 'food');
      expect(s.source, SuggestionSource.similarHistory);
    });

    test('learns custom categories from history', () {
      final s = CategorySuggester.suggest(
        merchant: 'Ramesh Kirana Store',
        history: history,
      )!;
      expect(s.categoryId, 'c_kirana');
    });

    test('falls back to the merchant dictionary', () {
      final s = CategorySuggester.suggest(
        merchant: 'UBER INDIA',
        history: const [],
      )!;
      expect(s.categoryId, 'transport');
      expect(s.source, SuggestionSource.dictionary);

      expect(
        CategorySuggester.suggest(
          title: 'Netflix monthly',
          history: const [],
        )!.categoryId,
        'entertainment',
      );
    });

    test('uses the title when there is no merchant', () {
      expect(
        CategorySuggester.suggest(
          title: 'IRCTC ticket',
          history: const [],
        )!.categoryId,
        'travel',
      );
    });

    test('ignores unavailable categories and unknown text', () {
      expect(
        CategorySuggester.suggest(
          merchant: 'Ramesh Kirana',
          history: history,
          isAvailable: (id) => id != 'c_kirana',
        )?.categoryId,
        'food', // dictionary: "kirana"
      );
      expect(
        CategorySuggester.suggest(merchant: 'zzqx', history: const []),
        isNull,
      );
      expect(CategorySuggester.suggest(merchant: '', history: history), isNull);
    });

    test('normalize strips punctuation and corporate suffixes', () {
      expect(
        CategorySuggester.normalize('SWIGGY*Bangalore Pvt. Ltd.'),
        'swiggy bangalore',
      );
    });
  });
}
