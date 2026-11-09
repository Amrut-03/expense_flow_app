import 'package:hive/hive.dart';

import '../../domain/entities/captured_transaction.dart';
import '../../domain/repositories/sms_capture_repository.dart';

/// Captured transactions live in an encrypted box as `id -> toMap()`;
/// the on/off flag and last-scan time live in the encrypted settings box.
class SmsCaptureRepositoryImpl implements SmsCaptureRepository {
  SmsCaptureRepositoryImpl({required this.box, required this.settingsBox});

  final Box<dynamic> box;
  final Box<dynamic> settingsBox;

  static const _enabledKey = 'sms_capture_enabled';
  static const _lastScanKey = 'sms_capture_last_scan_ms';

  @override
  bool isEnabled() => settingsBox.get(_enabledKey) == true;

  @override
  Future<void> setEnabled(bool enabled) =>
      settingsBox.put(_enabledKey, enabled);

  @override
  DateTime? lastScan() {
    final ms = settingsBox.get(_lastScanKey);
    return ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  @override
  Future<void> setLastScan(DateTime time) =>
      settingsBox.put(_lastScanKey, time.millisecondsSinceEpoch);

  @override
  bool contains(String id) => box.containsKey(id);

  @override
  List<CapturedTransaction> getAll() => box.values
      .map(CapturedTransaction.fromMap)
      .whereType<CapturedTransaction>()
      .toList();

  @override
  Future<void> saveAll(Iterable<CapturedTransaction> items) =>
      box.putAll({for (final i in items) i.id: i.toMap()});

  @override
  Future<void> save(CapturedTransaction item) => box.put(item.id, item.toMap());

  @override
  Stream<void> watch() => box.watch().map((_) {});
}
