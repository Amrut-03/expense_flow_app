import 'package:equatable/equatable.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendQuestion extends ChatEvent {
  final String question;

  const SendQuestion(this.question);

  @override
  List<Object?> get props => [question];
}

/// Re-sends the last question after an error, so the user can recover a failed
/// exchange without retyping it.
class RetryQuestion extends ChatEvent {
  const RetryQuestion();

  @override
  List<Object?> get props => [];
}
