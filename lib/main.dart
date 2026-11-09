import 'package:expense_flow_app/core/di/injection_container.dart' as di;
import 'package:expense_flow_app/core/logging/app_log_buffer.dart';
import 'package:expense_flow_app/core/background/background_summary_refresh_service.dart';
import 'package:expense_flow_app/core/notifications/budget_alert_watcher.dart';
import 'package:expense_flow_app/core/notifications/local_notification_service.dart';
import 'package:expense_flow_app/core/notifications/notification_payload.dart';
import 'package:expense_flow_app/core/notifications/notification_scheduler.dart';
import 'package:expense_flow_app/core/notifications/weekly_digest_service.dart';
import 'package:expense_flow_app/core/push/fcm_push_service.dart';
import 'package:expense_flow_app/core/router/app_router.dart';
import 'package:expense_flow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'core/di/injection_container.dart';
import 'core/storage/hive_boxes.dart';
import 'core/storage/secure_hive.dart';
import 'features/expense/data/models/expense_model.dart';
import 'package:hive/hive.dart';
import 'core/theme/theme_cubit.dart';
import 'firebase_options.dart';
import 'features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'features/app_lock/presentation/widgets/app_lock_gate.dart';
import 'features/currency/presentation/cubit/currency_cubit.dart';
import 'features/events/presentation/cubit/spending_events_cubit.dart';
import 'features/expense/presentation/bloc/expense_bloc.dart';
import 'features/budget/domain/usecases/get_budget_insights_usecase.dart';
import 'features/currency/presentation/util/currency_formatter.dart';
import 'features/home_widget/data/home_widget_sync.dart';
import 'features/home_widget/domain/home_widget_snapshot.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/budget/domain/usecases/settle_budget_rollover_usecase.dart';
import 'features/budget/presentation/bloc/budget_insights_cubit.dart';
import 'features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'features/budget/presentation/bloc/budget_limits_state.dart';
import 'features/categories/domain/repositories/category_repository.dart';
import 'features/expense/presentation/bloc/expense_state.dart';
import 'features/notifications/domain/entities/notification_type.dart';
import 'features/sms_capture/presentation/capture_notification_action_handler.dart';
import 'features/sms_capture/presentation/cubit/sms_capture_cubit.dart';
import 'features/recurring/domain/usecases/generate_due_recurring_expenses_usecase.dart';
import 'features/settings/presentation/cubit/locale_cubit.dart';
import 'features/sync/domain/usecases/push_pending_changes_usecase.dart';
import 'l10n/app_localizations.dart';

void main() {
  AppLogBuffer.instance.start();
  runZoned(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      _installGlobalErrorHandlers();

      await dotenv.load(fileName: ".env");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Opens every Hive box AES-encrypted (migrating legacy plaintext
      // boxes once) before anything else can touch Hive.
      await SecureHive.initialize();

      await di.initDependencyInjection();

      // Custom categories must be in the registry before the first frame,
      // since category lookups are synchronous everywhere.
      await sl<CategoryRepository>().initialize();
      unawaited(sl<CategoryRepository>().pullRemote());

      await _generateDueRecurringExpenses();
      unawaited(_settleBudgetRollover());

      final localNotifications = sl<LocalNotificationService>();
      await localNotifications.initialize(onTap: _handleNotificationTap);

      unawaited(localNotifications.requestPermissions());

      unawaited(_scheduleNotifications());
      sl<BudgetAlertWatcher>().start();

      unawaited(_initHomeWidget());
      unawaited(sl<BackgroundSummaryRefreshService>().refresh());
      unawaited(sl<FcmPushService>().initialize());

      runApp(const ExpenseFlowApp());
    },
    zoneSpecification: ZoneSpecification(
      // Capture the console stream verbatim: every `print`/`debugPrint` line
      // the terminal shows also lands in the log-report buffer exactly as-is,
      // then still reaches the real console.
      print: (self, parent, zone, line) {
        AppLogBuffer.instance.captureConsoleLine(line);
        parent.print(zone, line);
      },
      handleUncaughtError: (self, parent, zone, error, stackTrace) {
        _reportUnhandledError(error, stackTrace);
      },
    ),
  );
}

/// Hooks into Flutter's  error pipelines so nothing fails silently.
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
  // Console output only: the zone `print` hook mirrors it verbatim into the
  // log report, so the report always carries the same detail as the terminal.
  debugPrint('[ExpenseFlow] Unhandled error: $error');
  if (stack != null) debugPrint(stack.toString());
}

/// Logs any recurring expenses that fell due since the last launch, then
/// tries to sync them. Never blocks startup on failure.
Future<void> _generateDueRecurringExpenses() async {
  try {
    final created = await sl<GenerateDueRecurringExpensesUseCase>()();
    if (created > 0) unawaited(sl<PushPendingChangesUseCase>()());
  } catch (error, stackTrace) {
    AppLogBuffer.instance.captureError('recurring.generate', error, stackTrace);
  }
}

/// Prepares the home-screen widget and routes its taps (also from a cold
/// start) into the app.
Future<void> _initHomeWidget() async {
  final widget = sl<HomeWidgetSync>();
  await widget.initialize();
  void open(String route) => unawaited(
    _whenAppReady((context) async {
      // Tab branches use go; pushing them would stack a second shell.
      GoRouter.of(context).go(route);
    }),
  );
  final initial = await widget.initialRoute();
  if (initial != null) open(initial);
  widget.taps.listen(open);
}

/// Pushes fresh numbers to the home-screen widget.
void _pushHomeWidget(BuildContext context) {
  final insights = context.read<BudgetInsightsCubit>().state;
  final expenseState = context.read<ExpenseBloc>().state;
  final currency = context.read<CurrencyCubit>();
  unawaited(
    sl<HomeWidgetSync>().push(
      HomeWidgetSnapshot.build(
        now: DateTime.now(),
        expenses: expenseState is ExpenseLoaded ? expenseState.expenses : const [],
        hasBudgets: insights.safeToSpend.hasBudgets,
        safeToday: insights.safeToSpend.today,
        overBudgetCount: insights.safeToSpend.overBudgetCount,
        format: (inr) => CurrencyFormatter.format(
          cubit: currency,
          amountInInr: inr,
        ).replaceAll(RegExp(r'\.00$'), ''),
        appLockEnabled: context.read<AppLockCubit>().state.enabled,
      ),
    ),
  );
}

/// Moves last period's unspent budget into savings goals where the user
/// chose that. Idempotent per period; never blocks startup.
Future<void> _settleBudgetRollover() async {
  try {
    await sl<SettleBudgetRolloverUseCase>()();
  } catch (error, stackTrace) {
    AppLogBuffer.instance.captureError('budget.rollover', error, stackTrace);
  }
}

/// Schedules all local notifications, then — once startup has settled —
/// lets the on-device model reword the weekly digest (throttled and cached
/// inside [WeeklyDigestService], so this is cheap on most launches).
Future<void> _scheduleNotifications() async {
  final scheduler = sl<NotificationScheduler>();
  await scheduler.scheduleAll();
  scheduler.watchExpenses(
    Hive.box<ExpenseModel>(HiveBoxes.expenses).watch().map((_) {}),
  );
  await Future<void>.delayed(const Duration(seconds: 20));
  await sl<WeeklyDigestService>().refresh();
}

/// Routes the user to the screen associated with a tapped local notification,
/// or runs the pressed action button.
void _handleNotificationTap(String? payload, String? actionId) {
  final data = NotificationPayload.decode(payload);
  final refId = data?.refId;

  if (actionId != null &&
      refId != null &&
      data?.type == NotificationType.transactionCaptured) {
    unawaited(
      _whenAppReady(
        (context) => sl<CaptureNotificationActionHandler>().handle(
          context,
          actionId: actionId,
          captureId: refId,
        ),
      ),
    );
    return;
  }

  final type = data?.type ?? NotificationType.general;
  AppRouter.router.go(type.defaultRoute);
}

/// Runs [action] once the widget tree (and its bloc providers) exist —
/// immediately while running, or after the first frames on a cold start
/// launched from a notification button.
Future<void> _whenAppReady(
  Future<void> Function(BuildContext context) action,
) async {
  for (var i = 0; i < 100; i++) {
    final context = AppRouter.rootContext;
    if (context != null && context.mounted) {
      try {
        await action(context);
      } catch (error, stackTrace) {
        AppLogBuffer.instance.captureError(
          'notifications.action',
          error,
          stackTrace,
        );
      }
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
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
        BlocProvider<AppLockCubit>(create: (_) => sl<AppLockCubit>()),
        BlocProvider<SpendingEventsCubit>(
          create: (_) => sl<SpendingEventsCubit>()..load(),
        ),
        BlocProvider<BudgetInsightsCubit>(
          create: (_) => sl<BudgetInsightsCubit>()..refresh(),
        ),
        BlocProvider<SmsCaptureCubit>(
          create: (_) => sl<SmsCaptureCubit>()..scanNow(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ExpenseBloc, ExpenseState>(
            listenWhen: (_, state) => state is ExpenseLoaded,
            listener: (context, _) =>
                context.read<BudgetInsightsCubit>().refresh(),
          ),
          BlocListener<BudgetLimitsBloc, BudgetLimitsState>(
            listenWhen: (_, state) => state is BudgetLimitsLoaded,
            listener: (context, _) =>
                context.read<BudgetInsightsCubit>().refresh(),
          ),
          BlocListener<BudgetInsightsCubit, BudgetInsights>(
            listener: (context, _) => _pushHomeWidget(context),
          ),
          BlocListener<AppLockCubit, AppLockState>(
            listenWhen: (a, b) => a.enabled != b.enabled,
            listener: (context, _) => _pushHomeWidget(context),
          ),
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, state) =>
                state is Authenticated && previous is! Authenticated,
            listener: (_, _) => sl<CategoryRepository>().pullRemote(),
          ),
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
                      builder: (context, child) =>
                          AppLockGate(child: child ?? const SizedBox.shrink()),
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
      ),
    );
  }
}
