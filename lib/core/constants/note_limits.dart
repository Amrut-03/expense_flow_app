/// Shared limits for user-entered text fields.
///
/// Kept in a single place so the UI (counters / input lengthers) and the
/// use-case validation can never drift apart.
abstract final class NoteLimits {
  /// Maximum number of characters allowed for an expense note.
  static const int maxLength = 280;

  /// Maximum number of characters allowed for an expense title.
  static const int titleMaxLength = 80;
}