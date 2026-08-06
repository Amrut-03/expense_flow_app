import 'package:dio/dio.dart';
import 'package:expense_flow_app/core/error/error_formatter.dart';

/// Converts any error raised by the AI chat pipeline into a safe,
/// user-presentable message.
///
/// Builds on [friendlyError] and additionally understands the on-device model
/// lifecycle errors raised by the Gemma manager (no model installed, model not
/// downloaded, missing default model URL, or download failure) so the UI can
/// tell the user exactly what is missing instead of leaking Dart internals.
String aiFriendlyError(
  Object error, {
  String fallback = 'Sorry, I couldn\'t answer that. Please try again.',
}) {
  if (error is ArgumentError) {
    return 'Please type a question first.';
  }

  if (error is StateError) {
    return _modelLifecycleMessage(error.message, fallback);
  }

  if (error is DioException) {
    return 'I couldn\'t download the AI model. Check your connection and try again.';
  }

  return friendlyError(error, fallback: fallback);
}

String _modelLifecycleMessage(String message, String fallback) {
  final lower = message.toLowerCase();

  if (lower.contains('no ai model installed') ||
      lower.contains('no default model url')) {
    return 'The AI model is not ready yet. Please set it up in Settings first.';
  }

  if (lower.contains('model') || lower.contains('download')) {
    return 'The AI model failed to start. Please check your network and try again.';
  }

  return fallback;
}
