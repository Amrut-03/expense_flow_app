import 'package:equatable/equatable.dart';

/// A single chat message in the conversation.
class ChatMessage extends Equatable {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});

  static const ChatMessage typing = ChatMessage(text: '', isUser: false);

  @override
  List<Object?> get props => [text, isUser];
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
