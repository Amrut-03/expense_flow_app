import 'package:expense_flow_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:expense_flow_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppLockRepository extends Mock implements AppLockRepository {}

void main() {
  late _MockAppLockRepository repository;
  late DateTime now;

  AppLockCubit build({required bool enabled}) {
    when(() => repository.isEnabled()).thenReturn(enabled);
    return AppLockCubit(repository, now: () => now);
  }

  void authReturns(AppLockAuthResult result) {
    when(
      () => repository.authenticate(reason: any(named: 'reason')),
    ).thenAnswer((_) async => result);
  }

  setUp(() {
    repository = _MockAppLockRepository();
    now = DateTime(2026, 11, 7, 12);
    when(() => repository.setEnabled(any())).thenAnswer((_) async {});
    when(() => repository.isSupported()).thenAnswer((_) async => true);
  });

  group('cold start', () {
    test('starts locked when enabled', () {
      final cubit = build(enabled: true);
      expect(cubit.state.locked, isTrue);
      expect(cubit.state.enabled, isTrue);
    });

    test('starts unlocked when disabled', () {
      final cubit = build(enabled: false);
      expect(cubit.state.locked, isFalse);
    });
  });

  group('unlock', () {
    test('unlocks on success', () async {
      final cubit = build(enabled: true);
      authReturns(AppLockAuthResult.success);

      await cubit.unlock(reason: 'r');

      expect(cubit.state.locked, isFalse);
      expect(cubit.state.authenticating, isFalse);
    });

    test('stays locked and reports failure', () async {
      final cubit = build(enabled: true);
      authReturns(AppLockAuthResult.lockedOut);

      await cubit.unlock(reason: 'r');

      expect(cubit.state.locked, isTrue);
      expect(cubit.state.lastFailure, AppLockAuthResult.lockedOut);
    });

    test('disables the lock if the device credential was removed', () async {
      final cubit = build(enabled: true);
      authReturns(AppLockAuthResult.unavailable);

      await cubit.unlock(reason: 'r');

      expect(cubit.state.locked, isFalse);
      expect(cubit.state.enabled, isFalse);
      verify(() => repository.setEnabled(false)).called(1);
    });
  });

  group('relock on resume', () {
    Future<AppLockCubit> unlocked() async {
      final cubit = build(enabled: true);
      authReturns(AppLockAuthResult.success);
      await cubit.unlock(reason: 'r');
      return cubit;
    }

    test('relocks after the grace period', () async {
      final cubit = await unlocked();

      cubit.onBackgrounded();
      now = now.add(const Duration(seconds: 30));
      cubit.onForegrounded();

      expect(cubit.state.locked, isTrue);
    });

    test('does not relock within the grace period', () async {
      final cubit = await unlocked();

      cubit.onBackgrounded();
      now = now.add(const Duration(seconds: 29));
      cubit.onForegrounded();

      expect(cubit.state.locked, isFalse);
    });

    test('never locks when disabled', () {
      final cubit = build(enabled: false);

      cubit.onBackgrounded();
      now = now.add(const Duration(hours: 1));
      cubit.onForegrounded();

      expect(cubit.state.locked, isFalse);
    });
  });

  group('setEnabled', () {
    test('requires authentication before enabling', () async {
      final cubit = build(enabled: false);
      authReturns(AppLockAuthResult.success);

      final result = await cubit.setEnabled(true, reason: 'r');

      expect(result, AppLockAuthResult.success);
      expect(cubit.state.enabled, isTrue);
      // Enabling from settings must not lock the user out immediately.
      expect(cubit.state.locked, isFalse);
      verify(() => repository.setEnabled(true)).called(1);
    });

    test('keeps the lock off when authentication fails', () async {
      final cubit = build(enabled: false);
      authReturns(AppLockAuthResult.failed);

      final result = await cubit.setEnabled(true, reason: 'r');

      expect(result, AppLockAuthResult.failed);
      expect(cubit.state.enabled, isFalse);
      verifyNever(() => repository.setEnabled(any()));
    });

    test('reports unavailable on devices without a screen lock', () async {
      final cubit = build(enabled: false);
      when(() => repository.isSupported()).thenAnswer((_) async => false);

      final result = await cubit.setEnabled(true, reason: 'r');

      expect(result, AppLockAuthResult.unavailable);
      verifyNever(() => repository.authenticate(reason: any(named: 'reason')));
    });

    test('requires authentication to disable', () async {
      final cubit = build(enabled: true);
      authReturns(AppLockAuthResult.failed);

      await cubit.setEnabled(false, reason: 'r');

      expect(cubit.state.enabled, isTrue);
    });
  });
}
