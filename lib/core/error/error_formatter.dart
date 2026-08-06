import 'dart:async';
import 'package:dio/dio.dart';
import 'failures.dart';

/// Converts any thrown object into a safe, user-presentable message.
///
/// Prevents raw runtime internals (Dart type names, exception text, stack
/// fragments) from leaking into the UI. Known failure types pass their
/// message through, recognised infrastructure exceptions map to friendly
/// copy, and anything else falls back to a generic message.
String friendlyError(
  Object error, {
  String fallback = 'Something went wrong.',
}) {
  if (error is Failure) return error.message;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return status == null
            ? 'Server responded with an error.'
            : 'Server error ($status). Please try again later.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      default:
        return fallback;
    }
  }

  if (error is TimeoutException) {
    return 'The request timed out. Please try again.';
  }

  if (error is FormatException) {
    return 'The data received was invalid. Please try again.';
  }

  return fallback;
}
