import 'package:expense_flow_app/core/di/injection_container.dart' as di;
import 'package:expense_flow_app/core/background/background_summary_refresh_service.dart';
import 'package:expense_flow_app/core/notifications/budget_alert_watcher.dart';
import 'package:expense_flow_app/core/notifications/local_notification_service.dart';
import 'package:expense_flow_app/core/notifications/notification_payload.dart';
import 'package:expense_flow_app/core/notifications/notification_scheduler.dart';
import 'package:expense_flow_app/core/push/fcm_push_service.dart';
import 'package:expense_flow_app/core/router/app_router.dart';
import 'package:expense_flow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'core/di/injection_container.dart';
import 'core/theme/theme_cubit.dart';
import 'features/ai/data/models/embedding_chunk_model.dart';
import 'features/currency/presentation/cubit/currency_cubit.dart';
import 'features/expense/data/models/expense_model.dart';
import 'features/expense/presentation/bloc/expense_bloc.dart';
import 'features/budget/data/models/budget_model.dart';
import 'features/budget/domain/entities/budget_entity.dart';
import 'features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'features/notifications/data/models/app_notification_model.dart';
import 'features/settings/presentation/cubit/locale_cubit.dart';
import 'l10n/app_localizations.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      _installGlobalErrorHandlers();

      await Firebase.initializeApp();

      await Hive.initFlutter();

      Hive.registerAdapter(ExpenseModelAdapter());
      Hive.registerAdapter(BudgetModelAdapter());
      Hive.registerAdapter(BudgetPeriodAdapter());
      Hive.registerAdapter(EmbeddingChunkModelAdapter());
      Hive.registerAdapter(AppNotificationModelAdapter());

      await Hive.openBox<ExpenseModel>('expense_box');
      await Hive.openBox<BudgetModel>('budget_box');
      await Hive.openBox<EmbeddingChunkModel>('ai_embeddings_box');
      await Hive.openBox<dynamic>('ai_disclaimer_box');
      await Hive.openBox<AppNotificationModel>('notifications_box');
      await Hive.openBox<dynamic>('notification_state_box');
      await Hive.openBox<dynamic>('notification_settings_box');

      await di.initDependencyInjection();

      final localNotifications = sl<LocalNotificationService>();
      await localNotifications.initialize(onTap: _handleNotificationTap);
      unawaited(localNotifications.requestPermissions());

      unawaited(sl<NotificationScheduler>().scheduleAll());
      sl<BudgetAlertWatcher>().start();

      unawaited(sl<BackgroundSummaryRefreshService>().refresh());
      unawaited(sl<FcmPushService>().initialize());

      runApp(const ExpenseFlowApp());
    },
    (error, stack) {
      _reportUnhandledError(error, stack);
    },
  );
}

/// Hooks into Flutter's error pipelines so nothing fails silently.
///
/// `FlutterError.onError` catches framework build/layout/paint errors;
/// `PlatformDispatcher.instance.onError` catches uncaught async errors.
/// There is no crash-reporting backend wired yet, so both are logged.
void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _reportUnhandledError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    _reportUnhandledError(error, stack);
    return true;
  };
}

void _reportUnhandledError(Object error, StackTrace? stack) {
  assert(() {
    debugPrint('[ExpenseFlow] Unhandled error: $error');
    if (stack != null) debugPrint(stack.toString());
    return true;
  }());
}

/// Routes the user to the screen associated with a tapped local notification.
void _handleNotificationTap(String? payload) {
  final type = NotificationPayload.typeFrom(payload);
  AppRouter.router.go(type.defaultRoute);
}

class ExpenseFlowApp extends StatelessWidget {
  const ExpenseFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<ExpenseBloc>()),
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<CurrencyCubit>(
          create: (_) => sl<CurrencyCubit>()..initialize(),
        ),
        BlocProvider<LocaleCubit>(
          create: (_) => sl<LocaleCubit>()..initialize(),
        ),
        BlocProvider<BudgetLimitsBloc>(create: (_) => sl<BudgetLimitsBloc>()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<LocaleCubit, Locale>(
                builder: (context, locale) {
                  return MaterialApp.router(
                    title: 'ExpenseFlow',
                    routerConfig: AppRouter.router,
                    debugShowCheckedModeBanner: false,
                    onGenerateTitle: (context) =>
                        AppLocalizations.of(context).appTitle,
                    locale: locale,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    themeMode: themeState.mode == AppThemeMode.dark
                        ? ThemeMode.dark
                        : ThemeMode.light,
                    theme: ThemeData(
                      scaffoldBackgroundColor: const Color(0xFFE7ECF3),
                      colorScheme: ColorScheme.light(
                        primary: const Color(0xFFE8722C),
                        surface: const Color(0xFFE7ECF3),
                      ),
                    ),
                    darkTheme: ThemeData(
                      scaffoldBackgroundColor: const Color(0xFF1E2228),
                      colorScheme: ColorScheme.dark(
                        primary: const Color(0xFFE8722C),
                        surface: const Color(0xFF1E2228),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
