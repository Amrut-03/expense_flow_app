import '../../../categories/domain/services/category_suggester.dart';
import '../../../expense/domain/repositories/expense_repository.dart';
import '../entities/captured_transaction.dart';
import '../repositories/sms_capture_repository.dart';
import '../services/transaction_sms_parser.dart';

enum SmsCaptureToggleResult { enabled, disabled, permissionDenied, unsupported }

/// Turns SMS auto-detect on (requesting permission) or off.
class SetSmsCaptureEnabledUseCase {
  const SetSmsCaptureEnabledUseCase({
    required this.inbox,
    required this.repository,
  });

  final SmsInbox inbox;
  final SmsCaptureRepository repository;

  Future<SmsCaptureToggleResult> call(bool enable) async {
    if (!enable) {
      await repository.setEnabled(false);
      return SmsCaptureToggleResult.disabled;
    }
    if (!inbox.isSupported) return SmsCaptureToggleResult.unsupported;

    final granted =
        await inbox.hasPermission() || await inbox.requestPermission();
    if (!granted) return SmsCaptureToggleResult.permissionDenied;

    await repository.setEnabled(true);
    return SmsCaptureToggleResult.enabled;
  }
}

/// Reads new inbox SMS since the last scan, extracts debits and queues them
/// for review. Returns how many new payments were queued.
class ScanSmsForTransactionsUseCase {
  ScanSmsForTransactionsUseCase({
    required this.inbox,
    required this.repository,
    required this.expenseRepository,
    this.notifier,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Only payments this recent are announced; older ones (e.g. the first
  /// 30-day backfill) just wait in the review queue.
  static const notifyWindow = Duration(hours: 24);

  /// How far back the very first scan looks.
  static const initialLookback = Duration(days: 30);

  /// Two SMS for the same payment (bank + card network) arrive close together.
  static const duplicateWindow = Duration(minutes: 10);

  final SmsInbox inbox;
  final SmsCaptureRepository repository;
  final ExpenseRepository expenseRepository;
  final CaptureNotifier? notifier;
  final DateTime Function() _now;

  Future<int> call() async {
    if (!repository.isEnabled() || !inbox.isSupported) return 0;
    if (!await inbox.hasPermission()) return 0;

    final now = _now();
    final since = repository.lastScan() ?? now.subtract(initialLookback);
    final messages = await inbox.readSince(since);

    final expenses = (await expenseRepository.getExpenses())
        .where((e) => !e.isDeleted)
        .toList();
    final known = repository.getAll();
    final queued = <CapturedTransaction>[];
    var newest = since;

    // Oldest first so the earliest SMS of a duplicate pair wins.
    final ordered = [...messages]
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));

    for (final sms in ordered) {
      if (sms.receivedAt.isAfter(newest)) newest = sms.receivedAt;

      final id = 'sms_${sms.id}';
      if (repository.contains(id)) continue;

      final parsed = TransactionSmsParser.parse(
        sender: sms.sender,
        body: sms.body,
      );
      if (parsed == null) continue;

      final seen = [...known, ...queued];
      if (_isDuplicate(parsed, sms.receivedAt, seen)) continue;

      final suggestion = CategorySuggester.suggest(
        merchant: parsed.merchant,
        history: expenses,
      );

      final possibleDuplicate = expenses.any(
        (e) =>
            (e.amount - parsed.amount).abs() < 0.01 &&
            e.date.difference(sms.receivedAt).abs() < const Duration(days: 1),
      );

      queued.add(
        CapturedTransaction(
          id: id,
          smsId: sms.id,
          sender: sms.sender,
          body: sms.body,
          amount: parsed.amount,
          merchant: parsed.merchant,
          paymentMethod: parsed.paymentMethod,
          reference: parsed.reference,
          date: sms.receivedAt,
          suggestedCategoryId: suggestion?.categoryId,
          possibleDuplicate: possibleDuplicate,
        ),
      );
    }

    if (queued.isNotEmpty) await repository.saveAll(queued);
    await repository.setLastScan(newest);

    final fresh = queued
        .where(
          (c) => !c.possibleDuplicate && now.difference(c.date) <= notifyWindow,
        )
        .toList();
    if (fresh.isNotEmpty) {
      try {
        await notifier?.notify(fresh);
      } catch (_) {
        // Alerts are best-effort; the captures are already queued.
      }
    }
    return queued.length;
  }

  bool _isDuplicate(
    ParsedTransaction parsed,
    DateTime at,
    List<CapturedTransaction> seen,
  ) {
    for (final c in seen) {
      final sameRef =
          parsed.reference != null && parsed.reference == c.reference;
      final sameAmountClose =
          (c.amount - parsed.amount).abs() < 0.01 &&
          c.date.difference(at).abs() <= duplicateWindow;
      if (sameRef || sameAmountClose) return true;
    }
    return false;
  }
}

class GetPendingCapturesUseCase {
  const GetPendingCapturesUseCase(this.repository);
  final SmsCaptureRepository repository;

  List<CapturedTransaction> call() =>
      repository
          .getAll()
          .where((c) => c.status == CaptureStatus.pending)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
}

/// Marks a capture as reviewed. Reviewed captures are kept so the same SMS
/// is never queued again.
class ResolveCaptureUseCase {
  const ResolveCaptureUseCase(this.repository);
  final SmsCaptureRepository repository;

  Future<void> call(CapturedTransaction capture, {required bool accepted}) {
    return repository.save(
      capture.withStatus(
        accepted ? CaptureStatus.accepted : CaptureStatus.dismissed,
      ),
    );
  }
}
