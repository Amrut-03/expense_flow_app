import '../../entities/safety_verdict.dart';

/// Evaluates a user question against the app's AI safety rules.
///
/// Pure domain contract so the chat pipeline can reject unsafe questions
/// before spending any retrieval or generation effort.
abstract interface class AiSafetyPolicy {
  /// Returns whether [question] may proceed, and if not, the canned template
  /// response to use instead.
  SafetyVerdict assess(String question);
}
