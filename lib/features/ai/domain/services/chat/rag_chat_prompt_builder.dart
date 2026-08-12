import '../../entities/chat_turn.dart';
import '../../entities/retrieved_chunk.dart';
import 'chat_prompt_builder.dart';

/// Retrieval-augmented prompt builder for the Gemma chat model.
///
/// Composes a system instruction, the retrieved context entries, and the
/// user's question into a single prompt. The context section is capped at
/// [maxContextLength] characters so the prompt stays within the model's input
/// window.
///
/// The instruction is returned separately via [systemInstruction] so the
/// model receives it as its system message (chat-instruct models follow a
/// system message far more reliably than an instruction buried in the user
/// turn); [build] produces only the user-facing payload (context, prior
/// conversation, and the question).
class RagChatPromptBuilder implements ChatPromptBuilder {
  const RagChatPromptBuilder({
    this.systemInstruction = defaultSystemInstruction,
    this.maxContextLength = defaultMaxContextLength,
    this.maxHistoryTurns = defaultMaxHistoryTurns,
  }) : assert(maxContextLength > 0),
       assert(maxHistoryTurns > 0);

  /// Default instruction telling the model to answer from the provided
  /// context only, always addressing the user in the second person.
  static const String defaultSystemInstruction =
      'You are ExpenseFlow, a financial assistant that analyzes the USER\'s '
      'expense data. The user owns the data in the Context below; you only '
      'analyze it on their behalf. You are never the spender.\n'
      '\n'
      'Always refer to the user in the second person: "you spent", "your '
      'biggest expense", "your budget". Never say "I spent", "I need to '
      'control", or any other first-person phrase that implies the spending '
      'is yours.\n'
      '\n'
      'Answer the user\'s question using ONLY the data provided in the '
      'Context below. Never invent amounts, merchants, categories, or dates '
      'that are not in the Context. If the Context does not contain the '
      'answer, say that you do not know. Be concise and write the answer as '
      'plain text.\n'
      '\n'
      'Examples of correct phrasing:\n'
      'Context: "₹500 spent on Travel (Travel) on Jul 24."\n'
      'Question: "What is my biggest expense?"\n'
      'Correct: "Your biggest expense is ₹500 on Travel on Jul 24."\n'
      'Incorrect: "I spent ₹500 on Travel on Jul 24."\n'
      '\n'
      'Context: "Your Food budget of ₹4000 is 98% used."\n'
      'Question: "What expenses do I need to control?"\n'
      'Correct: "Your Food budget of ₹4000 is 98% used, so it is the expense '
      'to control first."\n'
      'Incorrect: "I need to control my Food spending."\n'
      '\n'
      'Context: "In July 2026 you spent ₹22000 across 14 transactions."\n'
      'Question: "How much did I spend in July?"\n'
      'Correct: "You spent ₹22000 in July 2026 across 14 transactions."\n'
      'Incorrect: "I spent ₹22000 in July."';

  /// Default cap on how many context characters are included in the prompt.
  static const int defaultMaxContextLength = 6000;

  /// Default cap on how many prior conversation turns are included.
  static const int defaultMaxHistoryTurns = 6;

  /// Instruction prefix given to the model.
  @override
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

    final buffer = StringBuffer('Context:\n$context')..writeln();

    if (conversation.isNotEmpty) {
      buffer
        ..writeln()
        ..write('Conversation:\n$conversation')
        ..writeln();
    }

    buffer
      ..writeln()
      ..write('Question: $question');

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
