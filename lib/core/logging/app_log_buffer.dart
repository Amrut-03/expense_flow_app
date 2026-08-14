/// Severity of a captured [AppLogEntry].
enum AppLogLevel { debug, info, warning, error }

/// A single line captured from the app runtime (console / framework output).
class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  final DateTime timestamp;
  final AppLogLevel level;
  final String message;
}

/// In-memory, bounded capture of everything the app prints from process start
/// (console stream, framework output, plugin/Dio logs) until it is exported as
/// a log report. Deliberately session-scoped: a fresh launch starts a fresh
/// buffer.
///
/// Every `print` / `debugPrint` line the terminal shows is captured verbatim
/// by the zone `print` hook installed in `main()` and lands here via
/// [captureConsoleLine]. Operational failures are additionally reported by the
/// catch blocks themselves through [captureError], so bug reports carry the
/// real exception type, message and stack — not only the friendly string shown
/// in the UI.
class AppLogBuffer {
  AppLogBuffer._();

  static final AppLogBuffer instance = AppLogBuffer._();

  /// Upper bound on buffered entries to keep memory flat on long sessions.
  static const int maxEntries = 6000;

  /// A single log line is truncated beyond this length so one huge JSON dump
  /// can't balloon the buffer; everything else is kept verbatim.
  static const int maxLineLength = 4000;

  final List<AppLogEntry> _entries = [];
  DateTime _startedAt = DateTime.now();

  DateTime get startedAt => _startedAt;

  /// Snapshot of the captured entries (newest last).
  List<AppLogEntry> get entries => List.unmodifiable(_entries);

  int get count => _entries.length;

  /// Must be called once, as the first thing in `main()`, before any console
  /// output is produced so the boot sequence is captured.
  void start() {
    _startedAt = DateTime.now();
    _entries.clear();
  }

  void _append(AppLogLevel level, String message) {
    if (message.length > maxLineLength) {
      message = '${message.substring(0, maxLineLength)}…[truncated]';
    }
    _entries.add(
      AppLogEntry(timestamp: DateTime.now(), level: level, message: message),
    );
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
  }

  /// Records a line exactly as it appeared in the terminal. Called from the
  /// zone `print` hook, so this is the verbatim console stream.
  void captureConsoleLine(String line) => _append(AppLogLevel.debug, line);

  /// Records an operational failure with its real exception type, message and
  /// stack trace, so the log report contains the underlying cause — not only
  /// the user-facing message.
  ///
  /// [context] names the operation that failed (e.g. `auth.signInWithGoogle`);
  /// the friendly message shown to the user should stay separate.
  void captureError(String context, Object error, [StackTrace? stackTrace]) {
    final buffer = StringBuffer()
      ..writeln('[ERROR] $context')
      ..writeln('  Type: ${error.runtimeType}')
      ..writeln('  Detail: $error');
    if (stackTrace != null && stackTrace.toString().isNotEmpty) {
      buffer
        ..writeln('  Stack:')
        ..writeln(stackTrace.toString());
    }
    _append(AppLogLevel.error, buffer.toString().trimRight());
  }

  /// All verbosity levels below are for explicit, semantic tagging; the raw
  /// console stream flows through [captureConsoleLine].
  void debug(String message) => _append(AppLogLevel.debug, message);

  void info(String message) => _append(AppLogLevel.info, message);

  void warning(String message) => _append(AppLogLevel.warning, message);

  void error(String message, [String? stackTrace]) {
    final text = stackTrace == null || stackTrace.isEmpty
        ? message
        : '$message\n$stackTrace';
    _append(AppLogLevel.error, text);
  }
}