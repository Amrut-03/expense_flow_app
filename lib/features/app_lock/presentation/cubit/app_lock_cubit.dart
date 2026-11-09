import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/repositories/app_lock_repository.dart';

class AppLockState extends Equatable {
  final bool enabled;
  final bool locked;
  final bool authenticating;

  /// Outcome of the most recent failed attempt, for UI feedback.
  final AppLockAuthResult? lastFailure;

  const AppLockState({
    required this.enabled,
    required this.locked,
    this.authenticating = false,
    this.lastFailure,
  });

  AppLockState copyWith({
    bool? enabled,
    bool? locked,
    bool? authenticating,
    AppLockAuthResult? lastFailure,
    bool clearFailure = false,
  }) {
    return AppLockState(
      enabled: enabled ?? this.enabled,
      locked: locked ?? this.locked,
      authenticating: authenticating ?? this.authenticating,
      lastFailure: clearFailure ? null : lastFailure ?? this.lastFailure,
    );
  }

  @override
  List<Object?> get props => [enabled, locked, authenticating, lastFailure];
}

/// Locks the app on cold start and after it has been in the background for
/// at least [relockAfter], when the user has turned app lock on.
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(
    this._repository, {
    this.relockAfter = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(
         AppLockState(
           enabled: _repository.isEnabled(),
           locked: _repository.isEnabled(),
         ),
       );

  final AppLockRepository _repository;
  final Duration relockAfter;
  final DateTime Function() _now;

  DateTime? _backgroundedAt;

  void onBackgrounded() {
    // The system auth sheet itself backgrounds the app on some devices.
    if (state.authenticating) return;
    _backgroundedAt ??= _now();
  }

  void onForegrounded() {
    final since = _backgroundedAt;
    _backgroundedAt = null;

    if (!state.enabled || state.locked || since == null) return;

    if (_now().difference(since) >= relockAfter) {
      emit(state.copyWith(locked: true, clearFailure: true));
    }
  }

  Future<void> unlock({required String reason}) async {
    if (!state.locked || state.authenticating) return;

    emit(state.copyWith(authenticating: true, clearFailure: true));

    final result = await _repository.authenticate(reason: reason);

    switch (result) {
      case AppLockAuthResult.success:
        emit(state.copyWith(locked: false, authenticating: false));
      case AppLockAuthResult.unavailable:
        // The device no longer has any screen lock, so there is nothing to
        // authenticate against. Keeping the app locked would lock the user
        // out of their own data permanently.
        AppLogBuffer.instance.captureError(
          'appLock.unavailable',
          StateError('Device credential removed; disabling app lock'),
          StackTrace.current,
        );
        await _repository.setEnabled(false);
        emit(const AppLockState(enabled: false, locked: false));
      case AppLockAuthResult.failed:
      case AppLockAuthResult.lockedOut:
        emit(state.copyWith(authenticating: false, lastFailure: result));
    }
  }

  /// Turns app lock on or off. Both directions require a successful
  /// authentication, so someone holding an unlocked phone can't silently
  /// disable it.
  Future<AppLockAuthResult> setEnabled(
    bool enabled, {
    required String reason,
  }) async {
    if (enabled == state.enabled) return AppLockAuthResult.success;

    if (enabled && !await _repository.isSupported()) {
      return AppLockAuthResult.unavailable;
    }

    emit(state.copyWith(authenticating: true));
    final result = await _repository.authenticate(reason: reason);

    if (result == AppLockAuthResult.success) {
      await _repository.setEnabled(enabled);
      emit(state.copyWith(enabled: enabled, authenticating: false));
    } else {
      emit(state.copyWith(authenticating: false));
    }

    return result;
  }
}
