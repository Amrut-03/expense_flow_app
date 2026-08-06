import '../../entities/chat_turn.dart';
import '../../entities/retrieved_chunk.dart';
import 'chat_prompt_builder.dart';

/// Retrieval-augmented prompt builder for the Gemma chat model.
///
/// Composes a system instruction, the retrieved context entries, and the
/// user's question into a single prompt. The context section is capped at
/// [maxContextLength] characters so the prompt stays within the model's input
/// window.
class RagChatPromptBuilder implements ChatPromptBuilder {
  const RagChatPromptBuilder({
    this.systemInstruction = defaultSystemInstruction,
    this.maxContextLength = defaultMaxContextLength,
    this.maxHistoryTurns = defaultMaxHistoryTurns,
  }) : assert(maxContextLength > 0),
       assert(maxHistoryTurns > 0);

  /// Default instruction telling the model to answer from the provided
  /// context only.
  static const String defaultSystemInstruction =
      'You are ExpenseFlow, a helpful expense assistant. Answer the user\'s '
      'question using only the context provided below. If the context does '
      'not contain the answer, say that you do not know. Be concise.';

  /// Default cap on how many context characters are included in the prompt.
  static const int defaultMaxContextLength = 6000;

  /// Default cap on how many prior conversation turns are included.
  static const int defaultMaxHistoryTurns = 6;

  /// Instruction prefix given to the model.
  final String systemInstruction;

  /// Maximum number of context characters rendered into the prompt.
  final int maxContextLength;

  /// Maximum number of prior conversation turns rendered into the prompt.
  final int maxHistoryTurns;

  @override
  String build({
    required String question,
    required List<RetrievedChunk> chunks,
    List<ChatTurn> history = const [],
  }) {
    final context = _buildContext(chunks);
    final conversation = _buildConversation(history);

    final buffer = StringBuffer(systemInstruction)
      ..writeln()
      ..writeln()
      ..write('Context:\n$context')
      ..writeln()
      ..writeln();

    if (conversation.isNotEmpty) {
      buffer
        ..write('Conversation:\n$conversation')
        ..writeln()
        ..writeln();
    }

    buffer
      ..write('Question: $question')
      ..writeln()
      ..writeln()
      ..write('Answer:');

    return buffer.toString();
  }

  /// Serialises [history] into a labelled transcript of prior exchanges.
  ///
  /// Each turn is prefixed with `User:` or `Assistant:` so the model can
  /// distinguish speakers. Keeps at most [maxHistoryTurns] turns so long
  /// sessions do not overflow the context window.
  String _buildConversation(List<ChatTurn> history) {
    final turns = history.length > maxHistoryTurns
        ? history.sublist(history.length - maxHistoryTurns)
        : history;

    return turns
        .map((turn) {
          final speaker = turn.isUser ? 'User' : 'Assistant';
          return '$speaker: ${turn.text}';
        })
        .join('\n');
  }

  /// Serialises [chunks] into context entries, honouring [maxContextLength].
  String _buildContext(List<RetrievedChunk> chunks) {
    final buffer = StringBuffer();
    var remaining = maxContextLength;

    for (final result in chunks) {
      if (remaining <= 0) break;

      final entry = '[${result.chunk.chunkType}] ${result.chunk.text}';
      if (entry.length > remaining) {
        buffer.write(entry.substring(0, remaining));
        remaining = 0;
      } else {
        buffer.writeln(entry);
        remaining -= entry.length + 1;
      }
    }

    return buffer.toString().trimRight();
  }
}
