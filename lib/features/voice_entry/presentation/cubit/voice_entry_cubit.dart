import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/voice_expense_draft.dart';
import '../../domain/services/speech_recognizer.dart';
import '../../domain/usecases/parse_voice_expense_usecase.dart';

enum VoicePhase { idle, listening, processing, done, failed }

class VoiceEntryState extends Equatable {
  final VoicePhase phase;
  final String localeId;
  final String partial;
  final bool onDevice;
  final SpeechFailure? failure;
  final VoiceExpenseDraft? draft;

  const VoiceEntryState({
    required this.localeId,
    this.phase = VoicePhase.idle,
    this.partial = '',
    this.onDevice = true,
    this.failure,
    this.draft,
  });

  VoiceEntryState copyWith({
    VoicePhase? phase,
    String? localeId,
    String? partial,
    bool? onDevice,
    SpeechFailure? failure,
    bool clearFailure = false,
    VoiceExpenseDraft? draft,
  }) {
    return VoiceEntryState(
      phase: phase ?? this.phase,
      localeId: localeId ?? this.localeId,
      partial: partial ?? this.partial,
      onDevice: onDevice ?? this.onDevice,
      failure: clearFailure ? null : (failure ?? this.failure),
      draft: draft ?? this.draft,
    );
  }

  @override
  List<Object?> get props => [phase, localeId, partial, onDevice, failure, draft];
}

class VoiceEntryCubit extends Cubit<VoiceEntryState> {
  VoiceEntryCubit({
    required this.recognizer,
    required this.parse,
    required this.categoryIds,
    required String localeId,
  }) : super(VoiceEntryState(localeId: localeId));

  /// Speech locales offered in the sheet.
  static const locales = ['en-IN', 'hi-IN', 'mr-IN'];

  /// Speech locale for an app language code.
  static String localeFor(String languageCode) => switch (languageCode) {
    'hi' => 'hi-IN',
    'mr' => 'mr-IN',
    _ => 'en-IN',
  };

  final SpeechRecognizer recognizer;
  final ParseVoiceExpenseUseCase parse;
  final List<String> categoryIds;
  bool _initialized = false;

  Future<void> start() async {
    if (state.phase == VoicePhase.listening ||
        state.phase == VoicePhase.processing) {
      return;
    }
    if (!_initialized) {
      final failure = await recognizer.initialize();
      if (failure != null) return _fail(failure);
      _initialized = true;
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        phase: VoicePhase.listening,
        partial: '',
        clearFailure: true,
      ),
    );

    final result = await recognizer.listen(
      localeId: state.localeId,
      onDevice: state.onDevice,
      onPartial: (text) {
        if (!isClosed && state.phase == VoicePhase.listening) {
          emit(state.copyWith(partial: text));
        }
      },
    );
    if (isClosed) return;

    final transcript = result.transcript?.trim() ?? '';
    if (transcript.isEmpty) return _fail(result.failure ?? SpeechFailure.noMatch);

    emit(state.copyWith(phase: VoicePhase.processing, partial: transcript));
    final draft = await parse(transcript, categoryIds: categoryIds);
    if (isClosed) return;
    if (draft.isEmpty) return _fail(SpeechFailure.noMatch);
    emit(state.copyWith(phase: VoicePhase.done, draft: draft));
  }

  Future<void> stop() => recognizer.stop();

  /// User agreed to let the platform recogniser use the network.
  Future<void> retryOnline() async {
    emit(state.copyWith(onDevice: false, phase: VoicePhase.idle));
    await start();
  }

  Future<void> selectLocale(String localeId) async {
    if (localeId == state.localeId) return;
    if (state.phase == VoicePhase.listening) await recognizer.cancel();
    emit(
      state.copyWith(
        localeId: localeId,
        phase: VoicePhase.idle,
        partial: '',
        onDevice: true,
        clearFailure: true,
      ),
    );
  }

  void _fail(SpeechFailure failure) {
    if (!isClosed) {
      emit(state.copyWith(phase: VoicePhase.failed, failure: failure));
    }
  }

  @override
  Future<void> close() async {
    await recognizer.cancel();
    return super.close();
  }
}
