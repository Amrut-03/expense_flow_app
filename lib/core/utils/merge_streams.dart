import 'dart:async';

/// Emits whenever any of [streams] emits. Subscribes lazily, cancels all
/// sources when the listener cancels.
Stream<void> mergeStreams(List<Stream<void>> streams) {
  late final StreamController<void> controller;
  final subscriptions = <StreamSubscription<void>>[];
  controller = StreamController<void>(
    onListen: () {
      for (final s in streams) {
        subscriptions.add(s.listen(controller.add));
      }
    },
    onCancel: () async {
      for (final s in subscriptions) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}
