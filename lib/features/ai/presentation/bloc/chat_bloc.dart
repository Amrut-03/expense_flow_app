import 'dart:async';

import 'package:expense_flow_app/core/logging/app_log_buffer.dart';
import 'package:expense_flow_app/features/ai/domain/entities/chat_turn.dart';
import 'package:expense_flow_app/features/ai/domain/usecases/ask_question_usecase.dart';
import 'package:expense_flow_app/features/ai/domain/usecases/embed_pending_chunks_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../utils/ai_error_message.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.askQuestion,
    EmbedPendingChunksUseCase? embedPendingChunks,
  }) : super(const ChatInitial()) {
    _embedPendingChunks = embedPendingChunks;
    _warmUpEmbeddingIndex();
    on<SendQuestion>(_onSend);
    on<RetryQuestion>(_onRetry);
  }

  final AskQuestionUseCase askQuestion;
  EmbedPendingChunksUseCase? _embedPendingChunks;

  bool _warmUpStarted = false;

  /// Kicks off a background pass that embeds any chunks that still lack
  /// vectors. Fire-and-forget: the first answer may rely on lexical
  /// retrieval, but once the pass completes later questions use the full
  /// semantic index. Failures never surface to the user.
  ///
  /// If the pass throws before finishing (for example the MiniLM model
  /// could not be initialised on the first attempt), [_warmUpStarted] is
  /// reset so a later question triggers a retry instead of leaving the chat
  /// permanently on the lexical fallback.
  void _warmUpEmbeddingIndex() {
    final embedPendingChunks = _embedPendingChunks;
    if (embedPendingChunks == null || _warmUpStarted) return;
    _warmUpStarted = true;

    unawaited(() async {
      try {
        await embedPendingChunks();
      } catch (error, stackTrace) {
        _warmUpStarted = false;
        AppLogBuffer.instance.captureError(
          'chat.embeddingWarmUp',
          error,
          stackTrace,
        );
      }
    }());
  }

  final List<ChatMessage> _conversation = [];

  bool _isSending = false;

  Future<void> _onSend(SendQuestion event, Emitter<ChatState> emit) async {
    final question = event.question.trim();
    if (question.isEmpty || _isSending) return;

    _isSending = true;
    try {
      _conversation.add(ChatMessage(text: question, isUser: true));
      emit(ChatLoading(List.unmodifiable(_conversation)));
      await _streamAnswer(question, emit);
    } finally {
      _isSending = false;
    }
  }

  Future<void> _onRetry(RetryQuestion event, Emitter<ChatState> emit) async {
    if (_isSending) return;

    // Find the last user question, dropping any trailing assistant message
    // (the previous error) so the retry re-answers in place.
    final lastUserIndex = _conversation.lastIndexWhere((m) => m.isUser);
    if (lastUserIndex < 0) return;

    final question = _conversation[lastUserIndex].text;
    _conversation.removeRange(lastUserIndex + 1, _conversation.length);

    _isSending = true;
    try {
      emit(ChatLoading(List.unmodifiable(_conversation)));
      await _streamAnswer(question, emit);
    } finally {
      _isSending = false;
    }
  }

  Future<void> _streamAnswer(String question, Emitter<ChatState> emit) async {
    try {
      // The question being answered is always the last message; everything
      // before it is prior conversational context.
      final history = _conversation
          .take(_conversation.length - 1)
          .map((m) => ChatTurn(text: m.text, isUser: m.isUser))
          .toList();

      final tokens = <String>[];
      await for (final rawToken in askQuestion(question, history: history)) {
        tokens.add(rawToken);
        emit(
          ChatAnswer(
            conversation: List.unmodifiable(_conversation),
            tokens: List.unmodifiable(tokens),
          ),
        );
      }

      final answer = ChatBloc.cleanAnswer(tokens.join());
      if (answer.isEmpty) {
        _conversation.add(
          const ChatMessage(
            text:
                'Sorry, I couldn\'t find anything to answer that with. '
                'Please try rephrasing your question.',
            isUser: false,
          ),
        );
      } else {
        _conversation.add(ChatMessage(text: answer, isUser: false));
      }
      emit(
        ChatAnswer(
          conversation: List.unmodifiable(_conversation),
          tokens: const [],
        ),
      );
    } catch (e) {
      AppLogBuffer.instance.captureError('chat.answer', e, StackTrace.current);
      final message = aiFriendlyError(e);
      _conversation.add(ChatMessage(text: message, isUser: false));
      emit(
        ChatError(
          conversation: List.unmodifiable(_conversation),
          message: message,
        ),
      );
    }
  }

  /// Removes the literal `\n` sequences that small on-device models emit
  /// instead of real line breaks, so answers render on a single clean line.
  static String cleanAnswer(String raw) {
    return raw
        .replaceAll(r'\n\n', ' ')
        .replaceAll(r'\n', ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }
}
