import 'package:equatable/equatable.dart';

/// A prior exchange between the user and the assistant.
///
/// Used to give the chat model conversational context across follow-up
/// questions within a session. [isUser] is true for the user's question and
/// false for the assistant's answer.
class ChatTurn extends Equatable {
  final String text;
  final bool isUser;

  const ChatTurn({required this.text, required this.isUser});

  @override
  List<Object?> get props => [text, isUser];
}
