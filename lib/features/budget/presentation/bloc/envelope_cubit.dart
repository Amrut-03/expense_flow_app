import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/envelope.dart';
import '../../domain/repositories/envelope_repository.dart';
import '../../domain/usecases/envelope_usecases.dart';

class EnvelopeState extends Equatable {
  final bool loading;
  final bool enabled;
  final EnvelopeMonth? month;

  const EnvelopeState({this.loading = true, this.enabled = false, this.month});

  @override
  List<Object?> get props => [loading, enabled, month];
}

class EnvelopeCubit extends Cubit<EnvelopeState> {
  EnvelopeCubit({
    required this.repository,
    required this.getMonth,
    required this.move,
    List<Stream<void>> changes = const [],
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const EnvelopeState()) {
    _subscriptions = [for (final s in changes) s.listen((_) => _schedule())];
  }

  final EnvelopeRepository repository;
  final GetEnvelopeMonthUseCase getMonth;
  final MoveEnvelopeMoneyUseCase move;
  final DateTime Function() _now;
  late final List<StreamSubscription<void>> _subscriptions;
  Timer? _debounce;

  Future<void> load() async {
    try {
      final enabled = repository.get().enabled;
      final month = enabled ? await getMonth() : null;
      if (!isClosed) {
        emit(EnvelopeState(loading: false, enabled: enabled, month: month));
      }
    } catch (e, st) {
      AppLogBuffer.instance.captureError('envelopes.load', e, st);
      if (!isClosed) emit(const EnvelopeState(loading: false));
    }
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> setEnabled(bool enabled) async {
    await repository.setEnabled(enabled, now: _now());
    await load();
  }

  Future<void> setIncome(double inr) async {
    await repository.setIncome(_now(), inr);
    await load();
  }

  Future<EnvelopeMoveError?> moveMoney({
    required String from,
    required String to,
    required double amount,
  }) async {
    final error = await move(from: from, to: to, amount: amount);
    if (error == null) await load();
    return error;
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }
}
