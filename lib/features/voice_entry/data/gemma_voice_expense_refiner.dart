import '../../ai/domain/services/answer/device_capability.dart';
import '../../ai/domain/services/gemma/gemma_manager.dart';
import '../domain/usecases/parse_voice_expense_usecase.dart';

/// Extracts expense fields with the on-device Gemma model, only when it's
/// already installed and the device has enough memory.
class GemmaVoiceExpenseRefiner implements VoiceExpenseRefiner {
  GemmaVoiceExpenseRefiner({
    required this.gemma,
    required this.device,
    this.minRamMb = 3000,
  });

  final GemmaManager gemma;
  final DeviceCapability device;
  final int minRamMb;

  static const systemInstruction =
      'You extract one expense from a short spoken sentence in English, '
      'Hindi or Marathi. Reply with a single JSON object and nothing else: '
      '{"amount": number|null, "title": string|null, "merchant": '
      'string|null, "category": string|null, "payment": string|null}. '
      'Use only information in the sentence. "title" is 1-4 words in the '
      'speaker\'s language describing what was bought. "payment" is one of '
      'Cash, Card, UPI, Bank Transfer, Other, or null.';

  @override
  Future<bool> isAvailable() async {
    final ram = await device.totalRamMb();
    if (ram != null && ram < minRamMb) return false;
    return gemma.hasActiveModel();
  }

  @override
  Future<String> extract(
    String transcript, {
    required List<String> categories,
  }) async {
    final prompt =
        'Categories: ${categories.join(', ')}\n'
        'Sentence: "$transcript"\n'
        'JSON:';
    final tokens = await gemma.generateResponse(
      prompt,
      systemInstruction: systemInstruction,
    );
    return (await tokens.toList()).join();
  }
}
