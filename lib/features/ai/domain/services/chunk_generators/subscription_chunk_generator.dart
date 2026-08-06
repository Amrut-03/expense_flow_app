import '../../entities/chunk_inputs.dart';
import 'chunk_generator.dart';
import 'chunk_text_formatter.dart';

/// Generates a natural-language chunk for a recurring subscription.
///
/// Produces text like:
/// `Netflix subscription: ₹499 per month, next charge on Aug 12.`
class SubscriptionChunkGenerator
    implements ChunkGenerator<SubscriptionChunkInput> {
  @override
  String get chunkType => 'subscription';

  @override
  String generate(SubscriptionChunkInput input) {
    final amount = ChunkTextFormatter.currency(input.amount);
    final date = ChunkTextFormatter.date(input.nextBillingDate);
    final cycle = switch (input.billingCycle) {
      'monthly' => 'month',
      'yearly' => 'year',
      final other => other,
    };

    return '${input.name} subscription: $amount per $cycle, '
        'next charge on $date.';
  }
}
