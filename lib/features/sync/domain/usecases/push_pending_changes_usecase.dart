import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/sync_repository.dart';

class PushPendingChangesUseCase {
  final SyncRepository repository;
  PushPendingChangesUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.pushPendingChanges();
  }
}
