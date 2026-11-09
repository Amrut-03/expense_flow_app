import 'dart:io';

import 'package:expense_flow_app/core/storage/hive_boxes.dart';
import 'package:expense_flow_app/core/storage/hive_encryption_key_store.dart';
import 'package:expense_flow_app/core/storage/secure_hive.dart';
import 'package:expense_flow_app/features/expense/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _MemoryKeyStore extends HiveEncryptionKeyStore {
  List<int>? key;

  @override
  Future<List<int>?> read() async => key;

  @override
  Future<List<int>> create() async => key = Hive.generateSecureKey();
}

ExpenseModel _expense(String id) {
  final date = DateTime(2026, 11, 7);
  return ExpenseModel(
    id: id,
    amount: 199,
    currency: 'INR',
    categoryId: 'food',
    title: 'Dosa',
    merchant: 'Vidyarthi Bhavan',
    date: date,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  late Directory dir;
  late _MemoryKeyStore keys;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('secure_hive_test');
    keys = _MemoryKeyStore();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  Future<void> restart() async {
    await Hive.close();
    await SecureHive.initialize(keyStore: keys, storagePath: dir.path);
  }

  test('migrates a legacy plaintext box without losing data', () async {
    // Simulate an install from before encryption.
    Hive.init(dir.path);
    SecureHive.registerAdapters();
    final legacy = await Hive.openBox<ExpenseModel>(HiveBoxes.expenses);
    await legacy.put('a', _expense('a'));
    await legacy.put('b', _expense('b'));
    final settings = await Hive.openBox<dynamic>(HiveBoxes.settings);
    await settings.put('selected_currency', 'USD');
    await Hive.close();

    await restart();

    final expenses = Hive.box<ExpenseModel>(HiveBoxes.expenses);
    expect(expenses.keys, unorderedEquals(['a', 'b']));
    expect(expenses.get('a')!.merchant, 'Vidyarthi Bhavan');
    expect(
      Hive.box<dynamic>(HiveBoxes.settings).get('selected_currency'),
      'USD',
    );
    expect(keys.key, isNotNull);
  });

  test('data written after migration survives restarts', () async {
    await restart();
    await Hive.box<ExpenseModel>(HiveBoxes.expenses).put('c', _expense('c'));

    await restart();
    await restart();

    expect(Hive.box<ExpenseModel>(HiveBoxes.expenses).get('c')?.title, 'Dosa');
  });

  test('box files are not readable without the key', () async {
    await restart();
    await Hive.box<ExpenseModel>(HiveBoxes.expenses).put('d', _expense('d'));
    await Hive.close();

    final raw = await File(
      '${dir.path}/${HiveBoxes.expenses}.hive',
    ).readAsBytes();
    final text = String.fromCharCodes(raw);

    expect(text.contains('Vidyarthi Bhavan'), isFalse);
    expect(text.contains('Dosa'), isFalse);
  });

  test('resets encrypted boxes cleanly when the key is lost', () async {
    await restart();
    await Hive.box<ExpenseModel>(HiveBoxes.expenses).put('e', _expense('e'));

    keys.key = null;
    await restart();

    // Old data is unrecoverable (it re-syncs from Firestore), but the app
    // boots with working, empty encrypted boxes and a fresh key.
    final expenses = Hive.box<ExpenseModel>(HiveBoxes.expenses);
    expect(expenses.isEmpty, isTrue);
    expect(keys.key, isNotNull);

    await expenses.put('f', _expense('f'));
    await restart();
    expect(Hive.box<ExpenseModel>(HiveBoxes.expenses).get('f'), isNotNull);
  });
}
