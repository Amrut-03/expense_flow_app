import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/logging/app_log_buffer.dart';
import '../domain/services/speech_recognizer.dart';

/// [SpeechRecognizer] backed by the `speech_to_text` plugin.
class SpeechToTextRecognizer implements SpeechRecognizer {
  final SpeechToText _speech = SpeechToText();

  Completer<({String? transcript, SpeechFailure? failure})>? _pending;
  String _latest = '';

  @override
  Future<SpeechFailure?> initialize() async {
    try {
      final ok = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
      if (ok) return null;
      final hasPermission = await _speech.hasPermission;
      return hasPermission
          ? SpeechFailure.unavailable
          : SpeechFailure.permissionDenied;
    } catch (e, st) {
      AppLogBuffer.instance.captureError('voice.init', e, st);
      return SpeechFailure.unavailable;
    }
  }

  @override
  Future<({String? transcript, SpeechFailure? failure})> listen({
    required String localeId,
    required bool onDevice,
    required void Function(String text) onPartial,
  }) async {
    await _speech.cancel();
    _latest = '';
    final completer =
        Completer<({String? transcript, SpeechFailure? failure})>();
    _pending = completer;

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _latest = result.recognizedWords;
          onPartial(_latest);
          if (result.finalResult) _finish(_latest, null);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          onDevice: onDevice,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (e, st) {
      AppLogBuffer.instance.captureError('voice.listen', e, st);
      _finish(null, SpeechFailure.other);
    }
    return completer.future;
  }

  void _onStatus(String status) {
    // "done"/"notListening" without a final result: use what we heard.
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        _finish(
          _latest.isEmpty ? null : _latest,
          _latest.isEmpty ? SpeechFailure.noMatch : null,
        );
      });
    }
  }

  void _onError(SpeechRecognitionError error) {
    final msg = error.errorMsg;
    final failure = switch (msg) {
      'error_permission' || 'error_insufficient_permissions' =>
        SpeechFailure.permissionDenied,
      'error_no_match' || 'error_speech_timeout' => SpeechFailure.noMatch,
      'error_language_unavailable' ||
      'error_language_not_supported' ||
      'error_server_disconnected' ||
      'error_network' ||
      'error_network_timeout' => SpeechFailure.languageUnavailableOffline,
      _ => SpeechFailure.other,
    };
    if (failure == SpeechFailure.other) {
      AppLogBuffer.instance.captureError(
        'voice.error',
        msg,
        StackTrace.current,
      );
    }
    _finish(_latest.isEmpty ? null : _latest, _latest.isEmpty ? failure : null);
  }

  void _finish(String? transcript, SpeechFailure? failure) {
    final c = _pending;
    if (c == null || c.isCompleted) return;
    _pending = null;
    c.complete((transcript: transcript, failure: failure));
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() async {
    await _speech.cancel();
    _finish(null, SpeechFailure.noMatch);
  }
}
