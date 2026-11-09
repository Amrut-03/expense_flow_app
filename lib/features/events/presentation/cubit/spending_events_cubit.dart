import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/spending_event.dart';
import '../../domain/repositories/spending_event_repository.dart';
import '../../domain/services/event_progress.dart';
import '../../domain/usecases/spending_event_usecases.dart';

class SpendingEventsState extends Equatable {
  final bool loading;
  final List<EventProgress> events;

  const SpendingEventsState({this.loading = true, this.events = const []});

  List<EventProgress> get active =>
      events.where((e) => e.status == EventStatus.active).toList();

  EventProgress? byId(String id) =>
      events.where((e) => e.event.id == id).firstOrNull;

  @override
  List<Object?> get props => [loading, events];
}

class SpendingEventsCubit extends Cubit<SpendingEventsState> {
  SpendingEventsCubit({
    required this.getProgress,
    required this.save,
    required this.delete,
    required this.repository,
    List<Stream<void>> changes = const [],
  }) : super(const SpendingEventsState()) {
    _subscriptions = [
      for (final stream in changes) stream.listen((_) => _scheduleLoad()),
    ];
  }

  final GetEventProgressUseCase getProgress;
  final SaveSpendingEventUseCase save;
  final DeleteSpendingEventUseCase delete;
  final SpendingEventRepository repository;
  late final List<StreamSubscription<void>> _subscriptions;
  Timer? _debounce;

  /// Plain event list without progress (pickers on the add-expense screen).
  List<SpendingEvent> get all => repository.getAll();

  Future<void> load() async {
    try {
      final events = await getProgress();
      if (!isClosed) emit(SpendingEventsState(loading: false, events: events));
    } catch (e, st) {
      AppLogBuffer.instance.captureError('events.load', e, st);
      if (!isClosed) emit(const SpendingEventsState(loading: false));
    }
  }

  void _scheduleLoad() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  /// Returns the validation error, or `null` on success.
  Future<EventValidationError?> saveEvent({
    String? id,
    required String name,
    required String emoji,
    required SpendingEventKind kind,
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
    Set<String> categoryIds = const {},
    String? currency,
    bool? separateFromBudgets,
  }) async {
    try {
      await save(
        id: id,
        name: name,
        emoji: emoji,
        kind: kind,
        startDate: startDate,
        endDate: endDate,
        budget: budget,
        categoryIds: categoryIds,
        currency: currency,
        separateFromBudgets: separateFromBudgets,
      );
      await load();
      return null;
    } on EventValidationException catch (e) {
      return e.error;
    }
  }

  Future<void> deleteEvent(String id) async {
    await delete(id);
    await load();
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
