import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/captured_transaction.dart';
import '../../domain/repositories/sms_capture_repository.dart';
import '../../domain/usecases/sms_capture_usecases.dart';

class SmsCaptureState extends Equatable {
  final bool supported;
  final bool enabled;
  final bool scanning;
  final List<CapturedTransaction> pending;

  const SmsCaptureState({
    required this.supported,
    required this.enabled,
    this.scanning = false,
    this.pending = const [],
  });

  SmsCaptureState copyWith({
    bool? enabled,
    bool? scanning,
    List<CapturedTransaction>? pending,
  }) {
    return SmsCaptureState(
      supported: supported,
      enabled: enabled ?? this.enabled,
      scanning: scanning ?? this.scanning,
      pending: pending ?? this.pending,
    );
  }

  @override
  List<Object?> get props => [supported, enabled, scanning, pending];
}

class SmsCaptureCubit extends Cubit<SmsCaptureState> {
  SmsCaptureCubit({
    required SmsInbox inbox,
    required this.repository,
    required this.scan,
    required this.setEnabled,
    required this.getPending,
    required this.resolve,
  }) : super(
         SmsCaptureState(
           supported: inbox.isSupported,
           enabled: repository.isEnabled(),
           pending: getPending(),
         ),
       ) {
    _changes = repository.watch().listen(
      (_) => emit(state.copyWith(pending: getPending())),
    );
    _lifecycle = AppLifecycleListener(onResume: scanNow);
  }

  final SmsCaptureRepository repository;
  final ScanSmsForTransactionsUseCase scan;
  final SetSmsCaptureEnabledUseCase setEnabled;
  final GetPendingCapturesUseCase getPending;
  final ResolveCaptureUseCase resolve;

  StreamSubscription<void>? _changes;
  AppLifecycleListener? _lifecycle;

  Future<void> scanNow() async {
    if (!state.enabled || state.scanning || isClosed) return;
    emit(state.copyWith(scanning: true));
    try {
      await scan();
    } catch (e, st) {
      AppLogBuffer.instance.captureError('sms.scan', e, st);
    }
    if (!isClosed) {
      emit(state.copyWith(scanning: false, pending: getPending()));
    }
  }

  Future<SmsCaptureToggleResult> toggle(bool enable) async {
    final result = await setEnabled(enable);
    emit(state.copyWith(enabled: repository.isEnabled()));
    if (result == SmsCaptureToggleResult.enabled) await scanNow();
    return result;
  }

  Future<void> markResolved(
    CapturedTransaction capture, {
    required bool accepted,
  }) {
    return resolve(capture, accepted: accepted);
  }

  @override
  Future<void> close() {
    _changes?.cancel();
    _lifecycle?.dispose();
    return super.close();
  }
}
