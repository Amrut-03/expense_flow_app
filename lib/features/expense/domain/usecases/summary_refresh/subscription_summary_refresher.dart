import 'package:expense_flow_app/features/ai/domain/entities/chunk_inputs.dart';
import 'package:expense_flow_app/features/ai/domain/services/chunk_generators/subscription_chunk_generator.dart';
import 'package:expense_flow_app/features/subscriptions/domain/usecases/subscription_usecases.dart';

import 'summary_chunk_refresher.dart';

/// One `subscription-<key>` chunk per detected subscription.
class SubscriptionSummaryRefresher implements PruningSummaryChunkRefresher {
  const SubscriptionSummaryRefresher({
    required this.detect,
    required this.generator,
  });

  final DetectSubscriptionsUseCase detect;
  final SubscriptionChunkGenerator generator;

  @override
  String get ownedChunkType => generator.chunkType;

  @override
  Future<List<DesiredChunk>> refresh() async {
    return [
      for (final sub in await detect())
        () {
          final input = SubscriptionChunkInput(
            id: 'subscription-${sub.key.replaceAll(' ', '-')}',
            name: sub.name,
            amount: sub.amount,
            billingCycle: sub.frequency.name,
            nextBillingDate: sub.nextExpected,
          );
          return DesiredChunk(
            id: input.id,
            chunkType: generator.chunkType,
            text: generator.generate(input),
            sourceId: input.id,
          );
        }(),
    ];
  }
}
