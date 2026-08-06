import 'package:hive/hive.dart';

import '../../domain/repositories/ai_disclaimer_repository.dart';

/// Hive-backed [AiDisclaimerRepository].
///
/// Stores a single boolean acknowledgement flag. No type adapter is required
/// because the box only holds primitives.
class AiDisclaimerRepositoryImpl implements AiDisclaimerRepository {
  AiDisclaimerRepositoryImpl({required this.box});

  /// Name of the Hive box backing this repository.
  static const String boxName = 'ai_disclaimer_box';

  static const String _seenKey = 'has_seen_disclaimer';

  /// The Hive box used for persistence.
  final Box<dynamic> box;

  @override
  Future<bool> hasSeenDisclaimer() async =>
      box.get(_seenKey, defaultValue: false) as bool;

  @override
  Future<void> markDisclaimerSeen() async {
    await box.put(_seenKey, true);
  }
}
