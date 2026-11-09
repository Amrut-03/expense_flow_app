import 'package:hive/hive.dart';

import '../../ai/domain/services/answer/device_capability.dart';
import '../../ai/domain/services/gemma/gemma_manager.dart';
import '../domain/usecases/weekly_digest_usecase.dart';

/// Rewrites digest facts with the on-device Gemma model, but only when a
/// model is already installed (never triggers a download) and the device has
/// enough memory.
class GemmaDigestWriter implements DigestWriter {
  GemmaDigestWriter({
    required this.gemma,
    required this.device,
    this.minRamMb = 3000,
  });

  final GemmaManager gemma;
  final DeviceCapability device;
  final int minRamMb;

  static const systemInstruction =
      'You rewrite a personal finance weekly digest. Keep every fact, amount '
      'and date exactly as given. Do not add advice, numbers or facts that '
      'are not in the input. Address the user as "you". Reply with at most '
      'three short lines and nothing else.';

  @override
  Future<bool> isAvailable() async {
    final ram = await device.totalRamMb();
    if (ram != null && ram < minRamMb) return false;
    return gemma.hasActiveModel();
  }

  @override
  Future<String> rewrite(List<String> facts) async {
    final prompt =
        'Rewrite these facts as a friendly weekly digest:\n'
        '${facts.map((f) => '- $f').join('\n')}';
    final tokens = await gemma.generateResponse(
      prompt,
      systemInstruction: systemInstruction,
    );
    return (await tokens.toList()).join();
  }
}

class HiveDigestCache implements DigestCache {
  HiveDigestCache(this.box);

  final Box<dynamic> box;

  static const _key = 'weekly_digest_ai';

  @override
  ({String factsKey, List<String> lines, DateTime writtenAt})? read() {
    final raw = box.get(_key);
    if (raw is! Map) return null;
    final facts = raw['factsKey'];
    final lines = raw['lines'];
    final at = raw['writtenAt'];
    if (facts is! String || lines is! List || at is! int) return null;
    return (
      factsKey: facts,
      lines: lines.whereType<String>().toList(),
      writtenAt: DateTime.fromMillisecondsSinceEpoch(at),
    );
  }

  @override
  Future<void> write(String factsKey, List<String> lines, DateTime writtenAt) {
    return box.put(_key, {
      'factsKey': factsKey,
      'lines': lines,
      'writtenAt': writtenAt.millisecondsSinceEpoch,
    });
  }
}
