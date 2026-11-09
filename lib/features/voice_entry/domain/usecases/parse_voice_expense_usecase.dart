import 'dart:convert';

import '../../../../core/constants/payment_methods.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../entities/voice_expense_draft.dart';
import '../services/voice_expense_parser.dart';

/// On-device LLM that turns a transcript into expense JSON.
abstract interface class VoiceExpenseRefiner {
  /// False on low-memory devices or when no model is installed (never
  /// triggers a download).
  Future<bool> isAvailable();

  /// Raw model output; expected to contain one JSON object with `amount`,
  /// `title`, `merchant`, `category` and `payment` keys.
  Future<String> extract(String transcript, {required List<String> categories});
}

/// Transcript → [VoiceExpenseDraft]: the rule-based parser always runs; the
/// on-device model only fills gaps, and anything it says is checked against
/// the transcript (it can't invent an amount or a merchant).
class ParseVoiceExpenseUseCase {
  ParseVoiceExpenseUseCase({
    required this.expenseRepository,
    this.refiner,
  });

  static const refineTimeout = Duration(seconds: 20);

  final ExpenseRepository expenseRepository;
  final VoiceExpenseRefiner? refiner;

  Future<VoiceExpenseDraft> call(
    String transcript, {
    required List<String> categoryIds,
    bool allowModel = true,
  }) async {
    final history = (await expenseRepository.getExpenses())
        .where((e) => !e.isDeleted)
        .toList();
    final draft = VoiceExpenseParser.parse(
      transcript,
      history: history,
      isAvailable: categoryIds.contains,
    );

    final r = refiner;
    if (!allowModel || r == null || draft.transcript.trim().isEmpty) {
      return draft;
    }
    if (!draft.isIncomplete && (draft.title?.split(' ').length ?? 0) <= 4) {
      return draft;
    }

    try {
      if (!await r.isAvailable()) return draft;
      final raw = await r
          .extract(transcript, categories: categoryIds)
          .timeout(refineTimeout);
      return merge(draft, raw, categoryIds: categoryIds);
    } catch (_) {
      return draft;
    }
  }

  /// Applies validated model fields to gaps in [draft].
  static VoiceExpenseDraft merge(
    VoiceExpenseDraft draft,
    String raw, {
    required List<String> categoryIds,
  }) {
    final json = _firstJsonObject(raw);
    if (json == null) return draft;

    final transcriptLower = VoiceExpenseParser.normalizeDigits(
      draft.transcript,
    ).toLowerCase();
    final spoken = VoiceExpenseParser.numbersIn(draft.transcript);

    double? amount;
    final rawAmount = json['amount'];
    final parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse('$rawAmount');
    if (parsedAmount != null &&
        parsedAmount > 0 &&
        spoken.any((n) => (n - parsedAmount).abs() < 0.01)) {
      amount = parsedAmount;
    }

    final category = json['category'];
    final validCategory = category is String && categoryIds.contains(category)
        ? category
        : null;

    final payment = json['payment'];
    final validPayment =
        payment is String && PaymentMethods.all.contains(payment)
        ? payment
        : null;

    final merchant = json['merchant'];
    final validMerchant =
        merchant is String &&
            merchant.trim().length >= 2 &&
            transcriptLower.contains(merchant.trim().toLowerCase())
        ? merchant.trim()
        : null;

    final title = json['title'];
    final validTitle =
        title is String && title.trim().isNotEmpty && title.trim().length <= 40
        ? title.trim()
        : null;

    final refined = VoiceExpenseDraft(
      transcript: draft.transcript,
      amount: draft.amount ?? amount,
      amountIsInr: draft.amountIsInr,
      title: validTitle ?? draft.title,
      merchant: draft.merchant ?? validMerchant,
      categoryId: draft.categoryId ?? validCategory,
      paymentMethod: draft.paymentMethod ?? validPayment,
    );
    return refined == draft.copyWith()
        ? draft
        : refined.copyWith(refinedByModel: true);
  }

  static Map<String, dynamic>? _firstJsonObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(raw.substring(start, end + 1));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
