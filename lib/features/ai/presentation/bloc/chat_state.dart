import 'package:equatable/equatable.dart';

import '../../domain/entities/answer_chart.dart';

/// A single chat message in the conversation.
class ChatMessage extends Equatable {
  final String text;
  final bool isUser;

  /// Chart computed from the user's data, shown under an answer.
  final AnswerChart? chart;

  const ChatMessage({required this.text, required this.isUser, this.chart});

  static const ChatMessage typing = ChatMessage(text: '', isUser: false);

  @override
  List<Object?> get props => [text, isUser, chart];
}

sealed class ChatState extends Equatable {
  const ChatState();

  /// The full conversation so far, in chronological order.
  List<ChatMessage> get messages => const [];

  @override
  List<Object?> get props => [messages];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  final List<ChatMessage> conversation;

  const ChatLoading(this.conversation);

  @override
  List<ChatMessage> get messages => conversation;

  @override
  List<Object?> get props => [conversation];
}

class ChatAnswer extends ChatState {
  final List<ChatMessage> conversation;

  /// Streamed tokens of the answer currently being generated.
  final List<String> tokens;

  const ChatAnswer({required this.conversation, required this.tokens});

  @override
  List<ChatMessage> get messages => conversation;

  @override
  List<Object?> get props => [conversation, tokens];
}

class ChatError extends ChatState {
  final List<ChatMessage> conversation;
  final String message;

  const ChatError({required this.conversation, required this.message});

  @override
  List<ChatMessage> get messages => conversation;

  @override
  List<Object?> get props => [conversation, message];
}
