import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/ai/data/models/embedding_chunk_model.dart';
import '../../features/budget/data/models/budget_model.dart';
import '../../features/budget/domain/entities/budget_entity.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../../features/notifications/data/models/app_notification_model.dart';
import '../../features/recurring/data/models/recurring_expense_model.dart';
import '../logging/app_log_buffer.dart';
import 'hive_boxes.dart';
import 'hive_encryption_key_store.dart';

/// A box name bound to its value type, so opening and migrating keep the
/// correct generic type at runtime.
class _BoxSpec<T> {
  const _BoxSpec(this.name);

  final String name;

  Future<Box<T>> open(HiveCipher? cipher) =>
      Hive.openBox<T>(name, encryptionCipher: cipher);

  /// Re-writes a legacy plaintext box encrypted.
  Future<void> migrate(HiveCipher cipher) async {
    final plain = await open(null);
    final entries = Map<dynamic, T>.of(plain.toMap());

    // `clear()` detaches HiveObject instances from the plaintext box so they
    // can be stored in the encrypted one.
    await plain.clear();
    await plain.deleteFromDisk();

    final secure = await open(cipher);
    await secure.putAll(entries);
  }
}

/// Boots Hive with every box encrypted at rest (AES-256, key held in the
/// platform keystore).
///
/// Existing plaintext boxes from earlier app versions are migrated in place
/// once; a flag per box in the unencrypted [HiveBoxes.meta] box records which
/// boxes are already encrypted, so a box is never opened with the wrong mode.
abstract final class SecureHive {
  static const _encryptedBoxesKey = 'encrypted_boxes';

  static const List<_BoxSpec<dynamic>> _boxes = [
    _BoxSpec<ExpenseModel>(HiveBoxes.expenses),
    _BoxSpec<BudgetModel>(HiveBoxes.budgets),
    _BoxSpec<RecurringExpenseModel>(HiveBoxes.recurringExpenses),
    _BoxSpec<EmbeddingChunkModel>(HiveBoxes.aiEmbeddings),
    _BoxSpec<AppNotificationModel>(HiveBoxes.notifications),
    _BoxSpec<dynamic>(HiveBoxes.aiDisclaimer),
    _BoxSpec<dynamic>(HiveBoxes.notificationState),
    _BoxSpec<dynamic>(HiveBoxes.notificationSettings),
    _BoxSpec<dynamic>(HiveBoxes.settings),
    _BoxSpec<dynamic>(HiveBoxes.exchangeRates),
    _BoxSpec<dynamic>(HiveBoxes.customCategories),
    _BoxSpec<dynamic>(HiveBoxes.savingsGoals),
    _BoxSpec<dynamic>(HiveBoxes.capturedTransactions),
    _BoxSpec<dynamic>(HiveBoxes.spendingEvents),
  ];

  /// Registers every Hive type adapter. Safe to call more than once (for
  /// example from a background isolate).
  static void registerAdapters() {
    void register<T>(TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter<T>(adapter);
      }
    }

    register(ExpenseModelAdapter());
    register(BudgetModelAdapter());
    register(BudgetPeriodAdapter());
    register(EmbeddingChunkModelAdapter());
    register(AppNotificationModelAdapter());
    register(RecurringExpenseModelAdapter());
  }

  /// Initializes Hive, migrates legacy plaintext boxes and opens every box
  /// encrypted. Must run before anything touches Hive.
  static Future<void> initialize({
    HiveEncryptionKeyStore? keyStore,
    @visibleForTesting String? storagePath,
  }) async {
    final store = keyStore ?? HiveEncryptionKeyStore();

    if (storagePath != null) {
      Hive.init(storagePath);
    } else {
      await Hive.initFlutter();
    }
    registerAdapters();

    final meta = await Hive.openBox<dynamic>(HiveBoxes.meta);
    final encrypted = _encryptedBoxes(meta);

    var key = await store.read();

    if (key == null) {
      if (encrypted.isNotEmpty) {
        // The key is gone (keystore reset / restored backup), so the
        // encrypted boxes are unreadable. Start clean; expenses, budgets and
        // settings are restored from Firestore by the regular sync.
        AppLogBuffer.instance.captureError(
          'secureHive.keyLost',
          StateError(
            'Encryption key missing; resetting ${encrypted.length} '
            'encrypted boxes',
          ),
          StackTrace.current,
        );
        for (final name in encrypted) {
          await Hive.deleteBoxFromDisk(name);
        }
        encrypted.clear();
        await meta.put(_encryptedBoxesKey, <String>[]);
      }
      key = await store.create();
    }

    final cipher = HiveAesCipher(key);

    for (final spec in _boxes) {
      final name = spec.name;

      if (!encrypted.contains(name) && await Hive.boxExists(name)) {
        await spec.migrate(cipher);
      } else {
        await spec.open(cipher);
      }

      if (encrypted.add(name)) {
        await meta.put(_encryptedBoxesKey, encrypted.toList());
      }
    }
  }

  /// Opens the notification inbox from the FCM background isolate, where
  /// [initialize] has not run. Never migrates: if the main isolate has not
  /// encrypted the box yet it is opened in its legacy plaintext mode.
  /// Returns `null` when the box cannot be opened safely.
  static Future<Box<AppNotificationModel>?> openNotificationsInBackground({
    HiveEncryptionKeyStore? keyStore,
  }) async {
    await Hive.initFlutter();
    registerAdapters();

    final meta = await Hive.openBox<dynamic>(HiveBoxes.meta);
    final isEncrypted = _encryptedBoxes(meta).contains(HiveBoxes.notifications);

    HiveCipher? cipher;
    if (isEncrypted) {
      final key = await (keyStore ?? HiveEncryptionKeyStore()).read();
      if (key == null) return null;
      cipher = HiveAesCipher(key);
    }

    return Hive.openBox<AppNotificationModel>(
      HiveBoxes.notifications,
      encryptionCipher: cipher,
    );
  }

  static Set<String> _encryptedBoxes(Box<dynamic> meta) {
    final stored = meta.get(_encryptedBoxesKey);
    return stored is List ? stored.whereType<String>().toSet() : <String>{};
  }
}
