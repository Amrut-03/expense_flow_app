import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/entities/detected_subscription.dart';
import '../../domain/usecases/subscription_usecases.dart';

class SubscriptionsState extends Equatable {
  final bool loading;
  final List<DetectedSubscription> items;

  const SubscriptionsState({this.loading = true, this.items = const []});

  double get monthlyTotal => items.fold(0, (sum, s) => sum + s.monthlyCost);

  @override
  List<Object?> get props => [loading, items];
}

class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  SubscriptionsCubit({required this.detect, required this.track})
    : super(const SubscriptionsState());

  final DetectSubscriptionsUseCase detect;
  final TrackSubscriptionUseCase track;

  Future<void> load() async {
    try {
      final items = await detect();
      if (!isClosed) emit(SubscriptionsState(loading: false, items: items));
    } catch (e, st) {
      AppLogBuffer.instance.captureError('subscriptions.load', e, st);
      if (!isClosed) emit(const SubscriptionsState(loading: false));
    }
  }

  Future<void> startTracking(DetectedSubscription sub) async {
    await track(sub);
    await load();
  }
}
