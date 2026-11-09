import 'dart:async';

import 'package:expense_flow_app/features/sms_capture/domain/entities/captured_transaction.dart';
import 'package:expense_flow_app/features/sms_capture/domain/repositories/sms_capture_repository.dart';
import 'package:expense_flow_app/features/sms_capture/domain/usecases/sms_capture_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/expense_factory.dart';
import '../../helpers/in_memory_expense_repository.dart';

class _FakeInbox implements SmsInbox {
  _FakeInbox(this.messages);

  final List<RawSms> messages;
  bool granted = true;
  bool grantOnRequest = true;
  DateTime? lastSince;

  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<bool> requestPermission() async => granted = grantOnRequest;

  @override
  Future<List<RawSms>> readSince(DateTime since, {int limit = 500}) async {
    lastSince = since;
    return messages.where((m) => m.receivedAt.isAfter(since)).toList();
  }
}

class _MemoryCaptureRepo implements SmsCaptureRepository {
  final Map<String, CapturedTransaction> items = {};
  bool enabled = true;
  DateTime? scannedAt;

  @override
  bool contains(String id) => items.containsKey(id);
  @override
  List<CapturedTransaction> getAll() => items.values.toList();
  @override
  bool isEnabled() => enabled;
  @override
  DateTime? lastScan() => scannedAt;
  @override
  Future<void> save(CapturedTransaction item) async => items[item.id] = item;
  @override
  Future<void> saveAll(Iterable<CapturedTransaction> list) async {
    for (final i in list) {
      items[i.id] = i;
    }
  }

  @override
  Future<void> setEnabled(bool value) async => enabled = value;
  @override
  Future<void> setLastScan(DateTime time) async => scannedAt = time;
  @override
  Stream<void> watch() => const Stream.empty();
}

class _RecordingNotifier implements CaptureNotifier {
  final List<List<CapturedTransaction>> calls = [];
  bool fail = false;
  @override
  Future<void> notify(List<CapturedTransaction> captures) async {
    calls.add(captures);
    if (fail) throw StateError('boom');
  }
}

RawSms sms(
  String id,
  String body,
  DateTime at, {
  String sender = 'AD-HDFCBK',
}) => RawSms(id: id, sender: sender, body: body, receivedAt: at);

void main() {
  final now = DateTime(2026, 11, 7, 20);
  late _MemoryCaptureRepo repo;
  late InMemoryExpenseRepository expenses;

  setUp(() {
    repo = _MemoryCaptureRepo();
    expenses = InMemoryExpenseRepository();
  });

  ScanSmsForTransactionsUseCase scanner(_FakeInbox inbox) =>
      ScanSmsForTransactionsUseCase(
        inbox: inbox,
        repository: repo,
        expenseRepository: expenses,
        now: () => now,
      );

  test('queues debits, skips non-transactions, suggests categories', () async {
    final inbox = _FakeInbox([
      sms(
        '1',
        'Sent Rs.250.00 From HDFC Bank A/C *1234 To SWIGGY On 05/11/26 '
            'Ref 431234567890',
        DateTime(2026, 11, 5, 13),
      ),
      sms('2', '123456 is your OTP. Do not share.', DateTime(2026, 11, 5, 14)),
      sms(
        '3',
        'Rs.5000.00 credited to A/c XX1234 by UPI ref 4312345',
        DateTime(2026, 11, 6),
      ),
    ]);

    final count = await scanner(inbox)();

    expect(count, 1);
    final capture = repo.items['sms_1']!;
    expect(capture.amount, 250);
    expect(capture.merchant, 'Swiggy');
    expect(capture.suggestedCategoryId, 'food');
    expect(capture.status, CaptureStatus.pending);
    expect(repo.scannedAt, DateTime(2026, 11, 6));
  });

  test('first scan looks back 30 days, then scans incrementally', () async {
    final inbox = _FakeInbox([]);
    await scanner(inbox)();
    expect(inbox.lastSince, now.subtract(const Duration(days: 30)));

    repo.scannedAt = DateTime(2026, 11, 6);
    await scanner(inbox)();
    expect(inbox.lastSince, DateTime(2026, 11, 6));
  });

  test('never re-queues an SMS already seen (even if dismissed)', () async {
    final body =
        'Spent Rs.99.00 On HDFC Bank Card 1234 At SPOTIFY On 2026-11-05';
    final inbox = _FakeInbox([sms('9', body, DateTime(2026, 11, 5))]);

    await scanner(inbox)();
    await repo.save(repo.items['sms_9']!.withStatus(CaptureStatus.dismissed));
    repo.scannedAt = null; // force a full re-read

    expect(await scanner(inbox)(), 0);
  });

  test('collapses two SMS for the same payment', () async {
    final at = DateTime(2026, 11, 5, 13);
    final inbox = _FakeInbox([
      sms(
        'a',
        'Spent Rs.1,499.00 On HDFC Bank Card 1234 At AMAZON On 2026-11-05',
        at,
      ),
      sms(
        'b',
        'Rs 1499.00 debited from card XX1234 at AMAZON on 05-11-26.',
        at.add(const Duration(minutes: 2)),
        sender: 'VM-HDFCCC',
      ),
    ]);

    expect(await scanner(inbox)(), 1);
  });

  test('flags a payment the user may already have logged', () async {
    await expenses.addExpense(
      expenseOf(
        amount: 250,
        date: DateTime(2026, 11, 5, 12),
        merchant: 'Swiggy',
      ),
    );
    final inbox = _FakeInbox([
      sms(
        '1',
        'Sent Rs.250.00 From HDFC Bank A/C *1234 To SWIGGY On 05/11/26',
        DateTime(2026, 11, 5, 13),
      ),
    ]);

    await scanner(inbox)();

    expect(repo.items['sms_1']!.possibleDuplicate, isTrue);
  });

  test('does nothing when disabled or permission was revoked', () async {
    final inbox = _FakeInbox([
      sms('1', 'Sent Rs.250.00 To SWIGGY On 05/11/26', DateTime(2026, 11, 5)),
    ]);

    repo.enabled = false;
    expect(await scanner(inbox)(), 0);

    repo.enabled = true;
    inbox.granted = false;
    expect(await scanner(inbox)(), 0);
  });

  group('SetSmsCaptureEnabledUseCase', () {
    test('enables only when permission is granted', () async {
      final inbox = _FakeInbox([])
        ..granted = false
        ..grantOnRequest = false;
      repo.enabled = false;
      final toggle = SetSmsCaptureEnabledUseCase(
        inbox: inbox,
        repository: repo,
      );

      expect(await toggle(true), SmsCaptureToggleResult.permissionDenied);
      expect(repo.enabled, isFalse);

      inbox.grantOnRequest = true;
      expect(await toggle(true), SmsCaptureToggleResult.enabled);
      expect(repo.enabled, isTrue);

      expect(await toggle(false), SmsCaptureToggleResult.disabled);
      expect(repo.enabled, isFalse);
    });
  });

  test('pending list excludes resolved captures, newest first', () async {
    final base = CapturedTransaction(
      id: 'x',
      smsId: 'x',
      sender: 'AD-HDFCBK',
      body: '',
      amount: 1,
      paymentMethod: 'UPI',
      date: DateTime(2026, 11, 1),
    );
    await repo.save(base);
    await repo.save(
      CapturedTransaction(
        id: 'y',
        smsId: 'y',
        sender: 'AD-HDFCBK',
        body: '',
        amount: 2,
        paymentMethod: 'UPI',
        date: DateTime(2026, 11, 3),
      ),
    );
    await ResolveCaptureUseCase(repo)(base, accepted: true);

    final pending = GetPendingCapturesUseCase(repo)();
    expect(pending.map((c) => c.id), ['y']);
    expect(repo.items['x']!.status, CaptureStatus.accepted);
  });

  group('capture notifications', () {
    String debit(String merchant, int amount) =>
        'Sent Rs.$amount.00 From HDFC Bank A/C *1234 To $merchant On 07/11/26';

    test('only fresh, non-duplicate captures are announced', () async {
      await expenses.addExpense(
        expenseOf(amount: 300, date: DateTime(2026, 11, 7, 18)),
      );
      final notifier = _RecordingNotifier();
      final inbox = _FakeInbox([
        sms('old', debit('SWIGGY', 120), DateTime(2026, 11, 1)),
        sms('new', debit('ZOMATO', 450), DateTime(2026, 11, 7, 19)),
        sms('dup', debit('UBER', 300), DateTime(2026, 11, 7, 18, 30)),
      ]);

      final count = await ScanSmsForTransactionsUseCase(
        inbox: inbox,
        repository: repo,
        expenseRepository: expenses,
        notifier: notifier,
        now: () => now,
      )();

      expect(count, 3);
      expect(notifier.calls.single.map((c) => c.id), ['sms_new']);
    });

    test('no call when nothing is fresh; failures do not break scans',
        () async {
      final notifier = _RecordingNotifier()..fail = true;
      final scan = ScanSmsForTransactionsUseCase(
        inbox: _FakeInbox([
          sms('a', debit('SWIGGY', 120), DateTime(2026, 11, 7, 19)),
        ]),
        repository: repo,
        expenseRepository: expenses,
        notifier: notifier,
        now: () => now,
      );
      expect(await scan(), 1);
      expect(repo.items.containsKey('sms_a'), isTrue);
      expect(await scan(), 0);
      expect(notifier.calls.length, 1);
    });
  });
}
