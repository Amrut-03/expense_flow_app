import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/sync_repository.dart';

class PullRemoteChangesUseCase {
  final SyncRepository repository;
  PullRemoteChangesUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.pullRemoteChanges();
  }
}
