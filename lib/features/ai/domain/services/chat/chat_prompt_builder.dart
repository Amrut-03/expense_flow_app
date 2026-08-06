import '../../entities/chat_turn.dart';
import '../../entities/retrieved_chunk.dart';

/// Contract for building a prompt for the Gemma chat model.
///
/// Implementations combine the retrieved context with the user's question
/// into a single prompt string. They are pure domain services: no network,
/// storage, or Flutter dependencies, so they are trivially testable.
abstract interface class ChatPromptBuilder {
  /// Returns the prompt for [question] grounded in [chunks].
  ///
  /// [history] carries earlier turns in the conversation so the model can
  /// answer follow-up questions (for example "which category was that?")
  /// without losing context from previous messages.
  String build({
    required String question,
    required List<RetrievedChunk> chunks,
    List<ChatTurn> history = const [],
  });
}
