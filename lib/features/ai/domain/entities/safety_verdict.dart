import 'package:equatable/equatable.dart';

import 'unsafe_topic.dart';

/// Outcome of evaluating a question against the AI safety policy.
///
/// Either the question is [SafetyVerdict.allowed] to proceed through the
/// pipeline, or it is rejected with a canned [template] response and the
/// [rejectedTopic] that triggered the rejection.
class SafetyVerdict extends Equatable {
  /// Constructs an allowed verdict.
  const SafetyVerdict.allowed() : rejectedTopic = null, template = null;

  /// Constructs a rejected verdict for the given [topic] with [template].
  const SafetyVerdict.rejected({
    required UnsafeTopic topic,
    required this.template,
  }) : rejectedTopic = topic;

  /// The topic that triggered the rejection, or null when allowed.
  final UnsafeTopic? rejectedTopic;

  /// Canned response to emit when rejected, or null when allowed.
  final String? template;

  /// Whether the question may proceed through the chat pipeline.
  bool get isAllowed => rejectedTopic == null;

  @override
  List<Object?> get props => [rejectedTopic, template];
}
