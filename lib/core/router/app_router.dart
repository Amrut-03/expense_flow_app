import 'package:expense_flow_app/features/insights/presentation/cubit/wrapped_cubit.dart';
import 'package:expense_flow_app/features/insights/presentation/screens/wrapped_screen.dart';
import 'package:expense_flow_app/features/budget/presentation/bloc/envelope_cubit.dart';
import 'package:expense_flow_app/features/budget/presentation/screens/envelopes_screen.dart';
import 'package:expense_flow_app/features/events/presentation/screens/events_screen.dart';
import 'package:expense_flow_app/features/groups/presentation/cubit/group_detail_cubit.dart';
import 'package:expense_flow_app/features/groups/presentation/cubit/groups_cubit.dart';
import 'package:expense_flow_app/features/groups/presentation/screens/group_detail_screen.dart';
import 'package:expense_flow_app/features/groups/presentation/screens/groups_screen.dart';
import 'package:expense_flow_app/core/notifications/notification_scheduler.dart';
import 'package:expense_flow_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:expense_flow_app/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:expense_flow_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:expense_flow_app/features/ai/presentation/screens/chat_screen.dart';
import 'package:expense_flow_app/features/ai/presentation/bloc/chat_bloc.dart';
import 'package:expense_flow_app/features/categories/presentation/screens/category_transaction_screen.dart';
import 'package:expense_flow_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:expense_flow_app/features/expense/domain/entities/expense_entity.dart';
import 'package:expense_flow_app/features/expense/presentation/screens/edit_expense_screen.dart';
import 'package:expense_flow_app/features/expense/presentation/screens/transaction_detail_screen.dart';
import 'package:expense_flow_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:expense_flow_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:expense_flow_app/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:expense_flow_app/features/notifications/presentation/bloc/notification_settings_cubit.dart';
import 'package:expense_flow_app/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:expense_flow_app/features/settings/presentation/screens/setting_screen.dart';
import 'package:expense_flow_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:expense_flow_app/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/budget/presentation/screens/budget_screen.dart';
import '../../features/budget/presentation/screens/edit_budget_screen.dart';
import '../../features/budget/presentation/screens/empty_budget_screen.dart';
import '../../features/dashboard/presentation/widgets/bottom_nav_bar.dart';
import '../../features/expense/presentation/screens/add_expense_screen.dart';
import '../../features/categories/presentation/screens/manage_categories_screen.dart';
import '../../features/goals/presentation/cubit/savings_goals_cubit.dart';
import '../../features/goals/presentation/screens/savings_goals_screen.dart';
import '../../features/recurring/presentation/cubit/recurring_expenses_cubit.dart';
import '../../features/sms_capture/presentation/screens/captured_transactions_screen.dart';
import '../../features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../features/subscriptions/presentation/screens/subscriptions_screen.dart';
import '../../features/tax/presentation/cubit/tax_summary_cubit.dart';
import '../../features/budget/presentation/bloc/budget_rollover_cubit.dart';
import '../../features/tax/presentation/screens/tax_summary_screen.dart';
import '../../features/reports/domain/usecases/export_usecases.dart';
import '../../features/reports/presentation/cubit/reports_cubit.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/reports/presentation/share_report.dart';
import '../../features/recurring/presentation/screens/recurring_expenses_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

  /// Context below the app's bloc providers, once the first frame is up.
  static BuildContext? get rootContext => _rootNavigatorKey.currentContext;

  static final router = GoRouter(
    observers: [routeObserver],
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            AppRouter._page(const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AppRouter._page(const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => AppRouter._page(const SignupScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            AppRouter._page(const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/category-transactions',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final category = extra is Map<String, dynamic>
              ? extra
              : const <String, dynamic>{};

          return AppRouter._page(
            CategoryTransactionScreen(
              categoryId: category['categoryId'] as String?,
              categoryName: category['label'] as String? ?? 'Transactions',
              categoryEmoji: category['emoji'] as String? ?? '💰',
            ),
          );
        },
      ),
      GoRoute(
        path: '/budget/edit',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<BudgetRolloverCubit>()..load(),
            child: const BudgetEditScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/transaction-detail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final expense = extra is ExpenseEntity ? extra : null;

          if (expense == null) {
            return AppRouter._page(const _RouteDataUnavailableScreen());
          }

          return AppRouter._page(TransactionDetailScreen(expense: expense));
        },
      ),
      GoRoute(
        path: '/edit-expense',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final expense = extra is ExpenseEntity ? extra : null;

          if (expense == null) {
            return AppRouter._page(const _RouteDataUnavailableScreen());
          }

          return AppRouter._page(EditTransactionScreen(expense: expense));
        },
      ),
      GoRoute(
        path: '/budget/empty',
        pageBuilder: (context, state) =>
            AppRouter._page(const BudgetEmptyStateScreen()),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<NotificationsCubit>()..load(),
            child: const NotificationsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/recurring',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<RecurringExpensesCubit>()..load(),
            child: const RecurringExpensesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/categories',
        pageBuilder: (context, state) =>
            AppRouter._page(const ManageCategoriesScreen()),
      ),
      GoRoute(
        path: '/subscriptions',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<SubscriptionsCubit>()..load(),
            child: const SubscriptionsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/envelopes',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<EnvelopeCubit>()..load(),
            child: const EnvelopesScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/wrapped',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => WrappedCubit(sl())..load(),
            child: const WrappedScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/groups',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<GroupsCubit>()..watch(),
            child: GroupsScreen(
              openGroup: (context, id) => context.push('/groups/$id'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/groups/:id',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) =>
                sl<GroupDetailCubit>(param1: state.pathParameters['id']!)
                  ..watch(),
            child: const GroupDetailScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/events',
        pageBuilder: (context, state) => AppRouter._page(const EventsScreen()),
      ),
      GoRoute(
        path: '/goals',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<SavingsGoalsCubit>()..load(),
            child: const SavingsGoalsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/tax-summary',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<TaxSummaryCubit>()..load(),
            child: TaxSummaryScreen(
              onExport: (context, summary) async {
                ExportResult result;
                try {
                  result = ExportReady(
                    await sl<ExportTaxSummaryCsvUseCase>()(summary),
                  );
                } catch (_) {
                  result = const ExportFailed();
                }
                if (context.mounted) {
                  await shareExport(
                    context,
                    result,
                    subject: summary.year.label,
                  );
                }
              },
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<ReportsCubit>()..load(),
            child: const ReportsScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/captures',
        pageBuilder: (context, state) =>
            AppRouter._page(const CapturedTransactionsScreen()),
      ),
      GoRoute(
        path: '/notification-settings',
        pageBuilder: (context, state) => AppRouter._page(
          BlocProvider(
            create: (_) => sl<NotificationSettingsCubit>()..load(),
            child: NotificationSettingsScreen(
              loggingTime: sl<NotificationScheduler>().loggingTime,
            ),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/budget',
                builder: (context, state) => const BudgetScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/add-expense',
                builder: (context, state) => const AddExpenseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<ChatBloc>(),
                  child: const ChatScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(),
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  /// Shared premium page transition for pushed routes: a gentle slide-up
  /// combined with a fade. Disabled automatically when the user has opted
  /// into reduced motion at the OS level.
  static CustomTransitionPage<void> _page(Widget child) {
    return CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
          return child;
        }

        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _RouteDataUnavailableScreen extends StatelessWidget {
  const _RouteDataUnavailableScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Requested data is unavailable')),
    );
  }
}
