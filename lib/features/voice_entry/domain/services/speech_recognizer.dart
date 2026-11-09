/// Why listening stopped without a usable transcript.
enum SpeechFailure {
  /// Microphone or speech permission denied.
  permissionDenied,

  /// No speech recogniser on this device.
  unavailable,

  /// The on-device language pack isn't installed; online recognition may
  /// still work if the user allows it.
  languageUnavailableOffline,

  /// Heard nothing intelligible.
  noMatch,

  other,
}

/// Device speech-to-text.
abstract interface class SpeechRecognizer {
  /// Prepares the recogniser (asks for permission the first time).
  Future<SpeechFailure?> initialize();

  /// Listens once. [onPartial] streams interim text; the returned future
  /// completes with the final transcript or a failure.
  ///
  /// [onDevice] keeps audio on the phone; when false the platform may use
  /// a network recogniser.
  Future<({String? transcript, SpeechFailure? failure})> listen({
    required String localeId,
    required bool onDevice,
    required void Function(String text) onPartial,
  });

  Future<void> stop();
  Future<void> cancel();
}
