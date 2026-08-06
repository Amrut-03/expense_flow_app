import 'package:equatable/equatable.dart';

/// Snapshot of the state of an embedding pipeline run.
///
/// Emitted via the pipeline's progress callback after every processed chunk
/// and once more when the run completes, so callers can drive progress UI and
/// learn about any chunks that could not be embedded.
class EmbeddingProgress extends Equatable {
  /// Number of chunks that needed embedding when the run started.
  final int total;

  /// Number of chunks that have been attempted so far.
  final int processed;

  /// Number of chunks successfully embedded and stored.
  final int succeeded;

  /// Number of chunks that failed and remain pending for a later run.
  final int failed;

  /// Whether the pipeline has finished draining its initial queue.
  final bool isCompleted;

  /// Ids of the chunks that failed during this run.
  final List<String> failedChunkIds;

  const EmbeddingProgress({
    required this.total,
    required this.processed,
    required this.succeeded,
    required this.failed,
    required this.isCompleted,
    this.failedChunkIds = const [],
  });

  /// Number of chunks still to be attempted.
  int get remaining => total - processed;

  @override
  List<Object?> get props => [
    total,
    processed,
    succeeded,
    failed,
    isCompleted,
    failedChunkIds,
  ];
}
