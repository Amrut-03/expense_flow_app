import '../entities/captured_transaction.dart';

/// Device SMS access. Android only; other platforms report unsupported.
abstract interface class SmsInbox {
  bool get isSupported;
  Future<bool> hasPermission();

  /// Shows the system permission prompt. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Inbox messages received strictly after [since].
  Future<List<RawSms>> readSince(DateTime since, {int limit});
}

/// Tells the user about freshly detected payments (e.g. an actionable
/// notification). Implementations decide whether alerts are enabled.
abstract interface class CaptureNotifier {
  Future<void> notify(List<CapturedTransaction> captures);
}

abstract interface class SmsCaptureRepository {
  bool isEnabled();
  Future<void> setEnabled(bool enabled);

  DateTime? lastScan();
  Future<void> setLastScan(DateTime time);

  bool contains(String id);
  List<CapturedTransaction> getAll();
  Future<void> saveAll(Iterable<CapturedTransaction> items);
  Future<void> save(CapturedTransaction item);

  Stream<void> watch();
}
