import '../constants/expense_category.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:expense_flow_app/features/auth/data/datasources/auth_datasource_impl.dart';
import 'package:expense_flow_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:expense_flow_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_flow_app/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:expense_flow_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:expense_flow_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:expense_flow_app/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:expense_flow_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:expense_flow_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:expense_flow_app/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:expense_flow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_flow_app/features/budget/data/datasources/local/budget_local_datasource_impl.dart';
import 'package:expense_flow_app/features/budget/data/datasources/remote/budget_remote_datasource.dart';
import 'package:expense_flow_app/features/budget/data/models/budget_model.dart';
import 'package:expense_flow_app/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:expense_flow_app/features/budget/data/repositories/budget_sync_repository_impl.dart';
import 'package:expense_flow_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_flow_app/features/budget/domain/repositories/budget_sync_repository.dart';
import 'package:expense_flow_app/features/budget/domain/usecases/get_budget_limits_usecase.dart';
import 'package:expense_flow_app/features/budget/domain/usecases/get_budget_periods_usecase.dart';
import 'package:expense_flow_app/features/budget/domain/usecases/pull_budget_changes_usecase.dart';
import 'package:expense_flow_app/features/budget/domain/usecases/push_budget_changes_usecase.dart';
import 'package:expense_flow_app/features/budget/domain/usecases/set_budget_limits_usecase.dart';
import 'package:expense_flow_app/features/budget/domain/usecases/watch_remote_budgets_usecase.dart';
import 'package:expense_flow_app/features/budget/presentation/bloc/budget_limits_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:hive/hive.dart';
import '../logging/app_log_buffer.dart';
import '../../features/currency/data/datasources/local/exchange_rate_local_datasource.dart';
import '../../features/currency/data/datasources/remote/exchange_rate_remote_datasource.dart';
import '../../features/currency/data/repositories/currency_converter_impl.dart';
import '../../features/currency/data/repositories/currency_repository_impl.dart';
import '../../features/currency/domain/repositories/currency_repository.dart';
import '../../features/currency/domain/usecases/change_currency_usecase.dart';
import '../../features/currency/domain/usecases/create_currency_converter_usecase.dart';
import '../../features/currency/domain/usecases/get_exchange_rate_usecase.dart';
import '../../features/currency/domain/usecases/get_selected_currency_usecase.dart';
import '../../features/currency/presentation/cubit/currency_cubit.dart';
import '../../features/expense/data/datasources/local/expense_local_datasource_impl.dart';
import '../../features/expense/data/datasources/remote/expense_remote_datasource.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../../features/expense/data/repositories/expense_repository_impl.dart';
import '../../features/expense/domain/repositories/expense_repository.dart';
import '../../features/expense/domain/usecases/add_expense_usecase.dart';
import '../../features/expense/domain/usecases/delete_expense_usecase.dart';
import '../../features/expense/domain/usecases/get_expense_usecase.dart';
import '../../features/expense/domain/usecases/update_expense_usecase.dart';
import '../../features/expense/presentation/bloc/expense_bloc.dart';
import '../../features/sync/data/repositories/sync_repository_impl.dart';
import '../../features/sync/domain/repositories/sync_repository.dart';
import '../../features/sync/domain/usecases/pull_remote_changes_usecase.dart';
import '../../features/sync/domain/usecases/push_pending_changes_usecase.dart';
import '../../features/sync/domain/usecases/watch_remote_expenses_usecase.dart';
import '../../features/ai/data/datasources/local/embedding_chunk_local_datasource.dart';
import '../../features/ai/data/datasources/local/embedding_chunk_local_datasource_impl.dart';
import '../../features/ai/data/models/embedding_chunk_model.dart';
import '../../features/ai/data/repositories/embedding_chunk_repository_impl.dart';
import '../../features/ai/domain/repositories/embedding_chunk_repository.dart';
import '../../features/ai/domain/services/chunk_generators/category_summary_chunk_generator.dart';
import '../../features/ai/domain/services/chunk_generators/monthly_summary_chunk_generator.dart';
import '../../features/ai/domain/services/chunk_generators/transaction_chunk_generator.dart';
import '../../features/ai/domain/services/chunk_generators/weekly_summary_chunk_generator.dart';
import '../../features/ai/domain/usecases/regenerate_transaction_chunks_usecase.dart';
import '../../features/ai/domain/services/chunk_generators/budget_chunk_generator.dart';
import '../../features/ai/data/datasources/local/embedding_model_datasource.dart';
import '../../features/ai/data/datasources/local/embedding_model_datasource_impl.dart';
import '../../features/ai/data/models/minilm/minilm_word_piece_tokenizer.dart';
import '../../features/ai/data/models/minilm/tflite_minilm_embedding_model.dart';
import '../../features/ai/data/repositories/embedding_repository_impl.dart';
import '../../features/ai/domain/repositories/embedding_repository.dart';
import '../../features/ai/domain/services/embedding/embedding_model.dart';
import '../../features/ai/domain/services/embedding/embedding_service.dart';
import '../../features/ai/domain/services/embedding/embedding_tokenizer.dart';
import '../../features/ai/domain/usecases/generate_embedding_usecase.dart';
import '../../features/ai/domain/usecases/embed_pending_chunks_usecase.dart';
import '../../features/ai/domain/usecases/embed_query_usecase.dart';
import '../../features/ai/domain/services/retrieval/top_k_retriever.dart';
import '../../features/ai/domain/services/retrieval/retrieval_service.dart';
import '../../features/ai/domain/services/retrieval/lexical_retrieval_service.dart';
import '../../features/ai/domain/services/retrieval/vector_retrieval_service.dart';
import '../../features/ai/domain/services/retrieval/hybrid_retrieval_service.dart';
import '../../features/ai/presentation/bloc/chat_bloc.dart';
import '../../features/ai/domain/services/gemma/gemma_manager.dart';
import '../../features/ai/data/gemma/gemma_manager_impl.dart';
import '../../features/ai/data/gemma/gemma_model_config.dart';
import 'package:flutter_gemma/flutter_gemma.dart' show ModelType;
import '../../features/ai/domain/services/chat/chat_prompt_builder.dart';
import '../../features/ai/domain/services/chat/rag_chat_prompt_builder.dart';
import '../../features/ai/domain/usecases/ask_question_usecase.dart';
import '../../features/ai/domain/services/safety/ai_safety_policy.dart';
import '../../features/ai/domain/services/safety/rule_based_ai_safety_policy.dart';
import '../../features/expense/domain/usecases/regenerate_ai_chunks_usecase.dart';
import '../../features/expense/domain/usecases/summary_refresh/budget_summary_refresher.dart';
import '../../features/expense/domain/usecases/summary_refresh/category_summary_refresher.dart';
import '../../features/expense/domain/usecases/summary_refresh/monthly_summary_refresher.dart';
import '../../features/expense/domain/usecases/summary_refresh/refresh_summaries_usecase.dart';
import '../../features/expense/domain/usecases/summary_refresh/transaction_summary_refresher.dart';
import '../../features/expense/domain/usecases/summary_refresh/weekly_summary_refresher.dart';
import '../../core/background/background_summary_refresh_service.dart';
import '../../core/theme/theme_cubit.dart';
import '../../features/settings/presentation/cubit/locale_cubit.dart';
import '../../features/settings/data/datasources/local/settings_local_datasource.dart';
import '../../features/settings/data/datasources/remote/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/user_settings_repository_impl.dart';
import '../../features/settings/domain/repositories/user_settings_repository.dart';
import '../../features/settings/domain/usecases/get_user_settings_usecase.dart';
import '../../features/settings/domain/usecases/pull_user_settings_usecase.dart';
import '../../features/settings/domain/usecases/sync_user_settings_usecase.dart';
import '../network/network_info.dart';
import '../network/dio_client.dart';
import '../notifications/budget_alert_evaluator.dart';
import '../notifications/budget_alert_watcher.dart';
import '../notifications/local_notification_service.dart';
import '../notifications/notification_scheduler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/notifications/data/datasources/notification_local_datasource.dart';
import '../../features/notifications/data/datasources/notification_local_datasource_impl.dart';
import '../../features/notifications/data/datasources/fcm_token_datasource.dart';
import '../../features/notifications/data/datasources/fcm_token_datasource_impl.dart';
import '../../features/notifications/data/datasources/notification_settings_local_datasource.dart';
import '../../features/notifications/data/models/app_notification_model.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/data/repositories/fcm_token_repository_impl.dart';
import '../../features/notifications/data/repositories/notification_settings_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/repositories/fcm_token_repository.dart';
import '../../features/notifications/domain/repositories/notification_settings_repository.dart';
import '../../features/notifications/domain/usecases/save_fcm_token_usecase.dart';
import '../../features/notifications/domain/usecases/save_notification_usecase.dart';
import '../../features/notifications/domain/usecases/watch_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import '../../features/notifications/domain/usecases/clear_notifications_usecase.dart';
import '../../features/notifications/domain/usecases/get_notification_settings_usecase.dart';
import '../../features/notifications/domain/usecases/update_notification_settings_usecase.dart';
import '../../features/notifications/presentation/bloc/notifications_cubit.dart';
import '../../features/notifications/presentation/bloc/notification_settings_cubit.dart';
import '../push/fcm_push_service.dart';
import '../../features/ai/data/device/device_info_capability.dart';
import '../../features/ai/domain/services/answer/answer_strategy.dart';
import '../../features/ai/domain/services/answer/device_capability.dart';
import '../storage/hive_boxes.dart';
import '../../features/budget/domain/usecases/get_budget_insights_usecase.dart';
import '../../features/budget/presentation/bloc/budget_insights_cubit.dart';
import '../../features/categories/data/datasources/category_remote_datasource.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/domain/usecases/custom_category_usecases.dart';
import '../../features/ai/domain/services/retrieval/vector_index_cache.dart';
import '../../features/budget/data/repositories/envelope_repository_impl.dart';
import '../../features/budget/domain/repositories/envelope_repository.dart';
import '../../features/ai/domain/usecases/build_answer_chart_usecase.dart';
import '../../features/home_widget/data/home_widget_sync.dart';
import '../../features/receipt_scan/data/mlkit_receipt_recognizer.dart';
import '../../features/receipt_scan/domain/services/receipt_recognizer.dart';
import '../../features/receipt_scan/domain/usecases/scan_receipt_usecase.dart';
import '../../features/budget/domain/services/budget_expense_filter.dart';
import '../utils/merge_streams.dart';
import '../../features/budget/domain/usecases/envelope_usecases.dart';
import '../../features/budget/presentation/bloc/envelope_cubit.dart';
import '../../features/events/data/repositories/spending_event_repository_impl.dart';
import '../../features/groups/data/firestore_group_repository.dart';
import '../../features/groups/domain/repositories/group_repository.dart';
import '../../features/groups/domain/usecases/group_usecases.dart';
import '../../features/groups/presentation/cubit/group_detail_cubit.dart';
import '../../features/groups/presentation/cubit/groups_cubit.dart';
import '../../features/events/domain/repositories/spending_event_repository.dart';
import '../../features/events/domain/services/separate_event_budget_filter.dart';
import '../../features/events/domain/usecases/spending_event_usecases.dart';
import '../../features/events/presentation/cubit/spending_events_cubit.dart';
import '../../features/goals/data/repositories/savings_goal_repository_impl.dart';
import '../../features/goals/domain/repositories/savings_goal_repository.dart';
import '../../features/goals/domain/usecases/savings_goal_usecases.dart';
import '../../features/goals/presentation/cubit/savings_goals_cubit.dart';
import '../../features/sms_capture/data/datasources/method_channel_sms_inbox.dart';
import '../../features/tax/domain/usecases/get_tax_summary_usecase.dart';
import '../../features/voice_entry/data/gemma_voice_expense_refiner.dart';
import '../../features/voice_entry/data/speech_to_text_recognizer.dart';
import '../../features/voice_entry/domain/services/speech_recognizer.dart';
import '../../features/voice_entry/domain/usecases/parse_voice_expense_usecase.dart';
import '../../features/voice_entry/presentation/cubit/voice_entry_cubit.dart';
import '../../features/reports/data/report_file_repository_impl.dart';
import '../../features/reports/domain/repositories/report_file_repository.dart';
import '../../features/reports/domain/usecases/export_usecases.dart';
import '../../features/reports/presentation/cubit/reports_cubit.dart';
import '../../features/budget/data/repositories/budget_rollover_repository_impl.dart';
import '../../features/budget/domain/repositories/budget_rollover_repository.dart';
import '../../features/budget/domain/usecases/settle_budget_rollover_usecase.dart';
import '../../features/budget/presentation/bloc/budget_rollover_cubit.dart';
import '../../features/tax/presentation/cubit/tax_summary_cubit.dart';
import '../../features/sms_capture/data/repositories/sms_capture_repository_impl.dart';
import '../../features/sms_capture/domain/repositories/sms_capture_repository.dart';
import '../../features/sms_capture/domain/usecases/sms_capture_usecases.dart';
import '../../features/sms_capture/presentation/cubit/sms_capture_cubit.dart';
import '../../features/sms_capture/presentation/capture_notification_action_handler.dart';
import '../../features/sms_capture/domain/entities/captured_transaction.dart';
import '../notifications/capture_notification_service.dart';
import '../../features/subscriptions/domain/usecases/subscription_usecases.dart';
import '../../features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import '../../features/ai/domain/services/chunk_generators/savings_goal_chunk_generator.dart';
import '../../features/ai/domain/services/chunk_generators/subscription_chunk_generator.dart';
import '../../features/expense/domain/usecases/summary_refresh/savings_goal_summary_refresher.dart';
import '../../features/expense/domain/usecases/summary_refresh/subscription_summary_refresher.dart';
import 'package:local_auth/local_auth.dart';
import '../../features/app_lock/data/repositories/app_lock_repository_impl.dart';
import '../../features/app_lock/domain/repositories/app_lock_repository.dart';
import '../../features/app_lock/presentation/cubit/app_lock_cubit.dart';
import '../../features/recurring/data/datasources/recurring_expense_local_datasource.dart';
import '../../features/recurring/data/models/recurring_expense_model.dart';
import '../../features/recurring/data/repositories/recurring_expense_repository_impl.dart';
import '../../features/recurring/domain/repositories/recurring_expense_repository.dart';
import '../../features/recurring/domain/usecases/generate_due_recurring_expenses_usecase.dart';
import '../../features/recurring/domain/usecases/manage_recurring_expenses_usecases.dart';
import '../../features/recurring/domain/usecases/start_recurring_expense_usecase.dart';
import '../../features/recurring/presentation/cubit/recurring_expenses_cubit.dart';
import '../../features/insights/data/weekly_digest_data.dart';
import '../../features/insights/domain/usecases/answer_affordability_usecase.dart';
import '../../features/insights/domain/usecases/weekly_digest_usecase.dart';
import '../notifications/weekly_digest_service.dart';

final sl = GetIt.instance;

Future<void> initDependencyInjection() async {
  sl.registerLazySingleton(() => fb.FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  final expenseBox = Hive.box<ExpenseModel>(HiveBoxes.expenses);

  sl.registerLazySingleton<Box<ExpenseModel>>(() => expenseBox);

  final googleSignIn = GoogleSignIn.instance;

  final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  if (serverClientId.isNotEmpty) {
    await googleSignIn.initialize(serverClientId: serverClientId);
  }

  sl.registerLazySingleton(() => googleSignIn);

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(firebaseAuth: sl(), googleSignIn: sl()),
  );

  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => SignInWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));

  sl.registerFactory(
    () => AuthBloc(
      getCurrentUserUseCase: sl(),
      signInUseCase: sl(),
      signUpUseCase: sl(),
      signInWithGoogleUseCase: sl(),
      signOutUseCase: sl(),
      forgotPasswordUseCase: sl(),
      updateProfileUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(
    () => DioClient(
      sl(),
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      authTokenProvider: () async {
        final user = sl<fb.FirebaseAuth>().currentUser;
        if (user == null) return null;
        try {
          return await user.getIdToken();
        } catch (e, st) {
          AppLogBuffer.instance.captureError('dio.authToken.di', e, st);
          return null;
        }
      },
    ),
  );

  // Expense DIs
  sl.registerLazySingleton<ExpenseLocalDataSource>(
    () => ExpenseLocalDataSourceImpl(sl<Box<ExpenseModel>>()),
  );

  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton(() => AddExpenseUseCase(sl<ExpenseRepository>()));

  sl.registerLazySingleton(() => GetExpensesUseCase(sl()));

  sl.registerLazySingleton(() => UpdateExpenseUseCase(sl<ExpenseRepository>()));

  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl<ExpenseRepository>()));

  // Recurring expense DIs
  sl.registerLazySingleton<Box<RecurringExpenseModel>>(
    () => Hive.box<RecurringExpenseModel>(HiveBoxes.recurringExpenses),
  );
  sl.registerLazySingleton<RecurringExpenseLocalDataSource>(
    () => RecurringExpenseLocalDataSourceImpl(sl<Box<RecurringExpenseModel>>()),
  );
  sl.registerLazySingleton<RecurringExpenseRepository>(
    () => RecurringExpenseRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(
    () => StartRecurringExpenseUseCase(
      repository: sl(),
      addExpense: sl<AddExpenseUseCase>(),
    ),
  );
  sl.registerLazySingleton(
    () => GenerateDueRecurringExpensesUseCase(
      repository: sl(),
      addExpense: sl<AddExpenseUseCase>(),
    ),
  );
  sl.registerLazySingleton(() => GetRecurringExpensesUseCase(sl()));
  sl.registerLazySingleton(() => WatchRecurringExpensesUseCase(sl()));
  sl.registerLazySingleton(() => SetRecurringExpenseActiveUseCase(sl()));
  sl.registerLazySingleton(() => DeleteRecurringExpenseUseCase(sl()));
  sl.registerFactory(
    () => RecurringExpensesCubit(
      getRules: sl(),
      watchRules: sl(),
      setActiveRule: sl(),
      deleteRule: sl(),
    ),
  );

  // App lock DIs
  sl.registerLazySingleton(() => LocalAuthentication());
  sl.registerLazySingleton<AppLockRepository>(
    () => AppLockRepositoryImpl(
      auth: sl(),
      settingsBox: Hive.box<dynamic>(HiveBoxes.settings),
    ),
  );
  sl.registerFactory(() => AppLockCubit(sl()));

  // Custom categories
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      box: Hive.box<dynamic>(HiveBoxes.customCategories),
      remote: CategoryRemoteDataSourceImpl(
        firestore: sl<FirebaseFirestore>(),
        getUid: () => sl<fb.FirebaseAuth>().currentUser?.uid,
      ),
    ),
  );
  sl.registerLazySingleton(() => CreateCustomCategoryUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomCategoryUseCase(sl()));
  sl.registerLazySingleton(() => ArchiveCustomCategoryUseCase(sl()));

  // Tax deductions (80C / 80D / HRA / 80G / 80E)
  sl.registerLazySingleton(() => GetTaxSummaryUseCase(sl<ExpenseRepository>()));
  sl.registerFactory(() => TaxSummaryCubit(sl<GetTaxSummaryUseCase>()));

  // Reports (monthly PDF statement, CSV export)
  sl.registerLazySingleton<ReportFileRepository>(
    () => ReportFileRepositoryImpl(),
  );
  sl.registerLazySingleton(
    () => GetMonthlyStatementUseCase(sl<ExpenseRepository>()),
  );
  sl.registerLazySingleton(
    () => ExportStatementPdfUseCase(
      getStatement: sl<GetMonthlyStatementUseCase>(),
      files: sl<ReportFileRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => ExportExpensesCsvUseCase(
      repository: sl<ExpenseRepository>(),
      files: sl<ReportFileRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => ExportTaxSummaryCsvUseCase(sl<ReportFileRepository>()),
  );
  sl.registerFactory(
    () => ReportsCubit(
      getStatement: sl<GetMonthlyStatementUseCase>(),
      exportPdf: sl<ExportStatementPdfUseCase>(),
      exportCsv: sl<ExportExpensesCsvUseCase>(),
    ),
  );

  // Budget rollover (carry forward / move to a savings goal)
  sl.registerLazySingleton<BudgetRolloverRepository>(
    () => BudgetRolloverRepositoryImpl(Hive.box<dynamic>(HiveBoxes.settings)),
  );
  sl.registerLazySingleton(
    () => SetBudgetRolloverUseCase(
      rolloverRepository: sl<BudgetRolloverRepository>(),
      budgetRepository: sl<BudgetRepository>(),
    ),
  );
  sl.registerFactory(
    () => BudgetRolloverCubit(
      repository: sl<BudgetRolloverRepository>(),
      setRollover: sl<SetBudgetRolloverUseCase>(),
      getGoals: sl<GetSavingsGoalsUseCase>(),
    ),
  );
  sl.registerLazySingleton(
    () => SettleBudgetRolloverUseCase(
      rolloverRepository: sl<BudgetRolloverRepository>(),
      budgetFilter: sl<BudgetExpenseFilter>(),
      budgetRepository: sl<BudgetRepository>(),
      expenseRepository: sl<ExpenseRepository>(),
      addContribution: sl<AddGoalContributionUseCase>(),
    ),
  );

  // Envelope (zero-based) budgeting
  sl.registerLazySingleton<EnvelopeRepository>(
    () => EnvelopeRepositoryImpl(Hive.box<dynamic>(HiveBoxes.settings)),
  );
  sl.registerLazySingleton(() => EnvelopeAdjustments(sl()));
  sl.registerLazySingleton(
    () => GetEnvelopeMonthUseCase(
      repository: sl(),
      budgetRepository: sl<BudgetRepository>(),
      expenseRepository: sl<ExpenseRepository>(),
      budgetFilter: sl<BudgetExpenseFilter>(),
    ),
  );
  sl.registerLazySingleton(() => MoveEnvelopeMoneyUseCase(sl()));
  sl.registerFactory(
    () => EnvelopeCubit(
      repository: sl(),
      getMonth: sl(),
      move: sl(),
      changes: [
        sl<EnvelopeRepository>().watch(),
        sl<Box<ExpenseModel>>().watch().map((_) {}),
      ],
    ),
  );

  // Budget insights (pace + safe to spend)
  sl.registerLazySingleton(
    () => GetBudgetInsightsUseCase(
      expenseRepository: sl<ExpenseRepository>(),
      budgetRepository: sl<BudgetRepository>(),
      recurringRepository: sl<RecurringExpenseRepository>(),
      rolloverRepository: sl<BudgetRolloverRepository>(),
      budgetFilter: sl<BudgetExpenseFilter>(),
      envelopes: sl<EnvelopeAdjustments>(),
    ),
  );
  sl.registerFactory(
    () => BudgetInsightsCubit(
      sl<GetBudgetInsightsUseCase>(),
      // Recurring rules, events (separate budgets) and envelope moves all
      // change the numbers.
      changes: mergeStreams([
        sl<RecurringExpenseRepository>().watch(),
        sl<SpendingEventRepository>().watch(),
        sl<EnvelopeRepository>().watch(),
      ]),
    ),
  );

  // Subscriptions
  sl.registerLazySingleton(
    () => DetectSubscriptionsUseCase(
      expenseRepository: sl<ExpenseRepository>(),
      recurringRepository: sl<RecurringExpenseRepository>(),
    ),
  );
  sl.registerLazySingleton(() => TrackSubscriptionUseCase(sl()));
  sl.registerFactory(() => SubscriptionsCubit(detect: sl(), track: sl()));

  sl.registerLazySingleton(HomeWidgetSync.new);
  sl.registerLazySingleton<ReceiptRecognizer>(MlKitReceiptRecognizer.new);
  sl.registerLazySingleton(() => ScanReceiptUseCase(sl()));

  // Shared groups (P3 3.2): Firestore-backed, multi-user.
  sl.registerLazySingleton<GroupRepository>(
    () => FirestoreGroupRepository(
      firestore: sl<FirebaseFirestore>(),
      getUid: () => sl<fb.FirebaseAuth>().currentUser?.uid,
      displayName: () {
        final user = sl<fb.FirebaseAuth>().currentUser;
        final name = user?.displayName?.trim();
        if (name != null && name.isNotEmpty) return name;
        final email = user?.email;
        return email == null ? 'Member' : email.split('@').first;
      },
    ),
  );
  sl.registerLazySingleton(
    () => AddGroupExpenseUseCase(
      sl<GroupRepository>(),
      addPersonalExpense: sl<AddExpenseUseCase>(),
    ),
  );
  sl.registerLazySingleton(
    () => RecordSettlementUseCase(sl<GroupRepository>()),
  );
  sl.registerLazySingleton(() => LeaveGroupUseCase(sl<GroupRepository>()));
  sl.registerFactory(() => GroupsCubit(sl<GroupRepository>()));
  sl.registerFactoryParam<GroupDetailCubit, String, void>(
    (groupId, _) => GroupDetailCubit(
      groupId: groupId,
      repository: sl<GroupRepository>(),
      addExpenseUseCase: sl<AddGroupExpenseUseCase>(),
      recordSettlement: sl<RecordSettlementUseCase>(),
      leaveGroup: sl<LeaveGroupUseCase>(),
    ),
  );

  // Events & trips (temporary budgets spanning categories)
  sl.registerLazySingleton<SpendingEventRepository>(
    () => SpendingEventRepositoryImpl(
      Hive.box<dynamic>(HiveBoxes.spendingEvents),
    ),
  );
  sl.registerLazySingleton<BudgetExpenseFilter>(
    () => SeparateEventBudgetFilter(sl<SpendingEventRepository>()),
  );
  sl.registerLazySingleton(() => SaveSpendingEventUseCase(sl()));
  sl.registerLazySingleton(
    () => DeleteSpendingEventUseCase(sl(), sl<ExpenseRepository>()),
  );
  sl.registerLazySingleton(
    () => GetEventProgressUseCase(sl(), sl<ExpenseRepository>()),
  );
  sl.registerFactory(
    () => SpendingEventsCubit(
      getProgress: sl(),
      save: sl(),
      delete: sl(),
      repository: sl<SpendingEventRepository>(),
      changes: [
        sl<SpendingEventRepository>().watch(),
        sl<Box<ExpenseModel>>().watch().map((_) {}),
      ],
    ),
  );

  // Savings goals
  sl.registerLazySingleton<SavingsGoalRepository>(
    () => SavingsGoalRepositoryImpl(Hive.box<dynamic>(HiveBoxes.savingsGoals)),
  );
  sl.registerLazySingleton(() => GetSavingsGoalsUseCase(sl()));
  sl.registerLazySingleton(() => CreateSavingsGoalUseCase(sl()));
  sl.registerLazySingleton(() => AddGoalContributionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSavingsGoalUseCase(sl()));
  sl.registerFactory(
    () => SavingsGoalsCubit(
      getGoals: sl(),
      createGoal: sl(),
      addContribution: sl(),
      deleteGoal: sl(),
      changes: sl<SavingsGoalRepository>().watch(),
    ),
  );

  // SMS auto-capture
  sl.registerLazySingleton<SmsInbox>(() => MethodChannelSmsInbox());
  sl.registerLazySingleton<SmsCaptureRepository>(
    () => SmsCaptureRepositoryImpl(
      box: Hive.box<dynamic>(HiveBoxes.capturedTransactions),
      settingsBox: Hive.box<dynamic>(HiveBoxes.settings),
    ),
  );
  sl.registerLazySingleton(
    () => ScanSmsForTransactionsUseCase(
      inbox: sl(),
      repository: sl(),
      expenseRepository: sl<ExpenseRepository>(),
      // Resolved lazily: notification services are registered later.
      notifier: _LazyCaptureNotifier(),
    ),
  );
  sl.registerLazySingleton(
    () => CaptureNotificationActionHandler(sl<SmsCaptureRepository>()),
  );
  sl.registerLazySingleton(
    () => SetSmsCaptureEnabledUseCase(inbox: sl(), repository: sl()),
  );
  sl.registerLazySingleton(() => GetPendingCapturesUseCase(sl()));
  sl.registerLazySingleton(() => ResolveCaptureUseCase(sl()));
  sl.registerFactory(
    () => SmsCaptureCubit(
      inbox: sl(),
      repository: sl(),
      scan: sl(),
      setEnabled: sl(),
      getPending: sl(),
      resolve: sl(),
    ),
  );

  sl.registerFactory(
    () => ExpenseBloc(
      addExpenseUseCase: sl(),
      startRecurringExpenseUseCase: sl(),
      getExpensesUseCase: sl(),
      updateExpenseUseCase: sl(),
      deleteExpenseUseCase: sl(),
      regenerateAiChunksUseCase: sl<RegenerateAiChunksUseCase>(),
      pushPendingChangesUseCase: sl<PushPendingChangesUseCase>(),
      pullRemoteChangesUseCase: sl<PullRemoteChangesUseCase>(),
      watchRemoteExpensesUseCase: sl<WatchRemoteExpensesUseCase>(),
      embedPendingChunksUseCase: sl<EmbedPendingChunksUseCase>(),
    ),
  );

  // AI chunk generation DIs
  final aiEmbeddingsBox = Hive.box<EmbeddingChunkModel>(HiveBoxes.aiEmbeddings);
  sl.registerLazySingleton<Box<EmbeddingChunkModel>>(() => aiEmbeddingsBox);

  sl.registerLazySingleton<EmbeddingChunkLocalDataSource>(
    () => EmbeddingChunkLocalDataSourceImpl(sl<Box<EmbeddingChunkModel>>()),
  );

  sl.registerLazySingleton<EmbeddingChunkRepository>(
    () => EmbeddingChunkRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton(() => TransactionChunkGenerator());
  sl.registerLazySingleton(() => MonthlySummaryChunkGenerator());
  sl.registerLazySingleton(() => WeeklySummaryChunkGenerator());
  sl.registerLazySingleton(() => CategorySummaryChunkGenerator());

  sl.registerLazySingleton(
    () => RegenerateTransactionChunksUseCase(
      repository: sl<EmbeddingChunkRepository>(),
      transactionChunkGenerator: sl(),
      monthlySummaryChunkGenerator: sl(),
      weeklySummaryChunkGenerator: sl(),
      categorySummaryChunkGenerator: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => RegenerateAiChunksUseCase(
      expenseRepository: sl<ExpenseRepository>(),
      regenerateTransactionChunks: sl<RegenerateTransactionChunksUseCase>(),
    ),
  );

  sl.registerLazySingleton(() => BudgetChunkGenerator());

  sl.registerLazySingleton(
    () => MonthlySummaryRefresher(
      expenseRepository: sl<ExpenseRepository>(),
      generator: sl<MonthlySummaryChunkGenerator>(),
    ),
  );

  sl.registerLazySingleton(
    () => BudgetSummaryRefresher(
      budgetRepository: sl<BudgetRepository>(),
      expenseRepository: sl<ExpenseRepository>(),
      generator: sl<BudgetChunkGenerator>(),
    ),
  );

  sl.registerLazySingleton(
    () => TransactionSummaryRefresher(
      expenseRepository: sl<ExpenseRepository>(),
      generator: sl<TransactionChunkGenerator>(),
    ),
  );

  sl.registerLazySingleton(
    () => WeeklySummaryRefresher(
      expenseRepository: sl<ExpenseRepository>(),
      generator: sl<WeeklySummaryChunkGenerator>(),
    ),
  );

  sl.registerLazySingleton(
    () => CategorySummaryRefresher(
      expenseRepository: sl<ExpenseRepository>(),
      generator: sl<CategorySummaryChunkGenerator>(),
    ),
  );

  sl.registerLazySingleton(
    () => RefreshSummariesUseCase(
      chunkRepository: sl<EmbeddingChunkRepository>(),
      refreshers: [
        sl<MonthlySummaryRefresher>(),
        sl<BudgetSummaryRefresher>(),
        sl<TransactionSummaryRefresher>(),
        sl<WeeklySummaryRefresher>(),
        sl<CategorySummaryRefresher>(),
        SubscriptionSummaryRefresher(
          detect: sl<DetectSubscriptionsUseCase>(),
          generator: SubscriptionChunkGenerator(),
        ),
        SavingsGoalSummaryRefresher(
          repository: sl<SavingsGoalRepository>(),
          generator: SavingsGoalChunkGenerator(),
        ),
      ],
    ),
  );

  sl.registerLazySingleton(
    () => BackgroundSummaryRefreshService(
      refreshSummariesUseCase: sl<RefreshSummariesUseCase>(),
      embedPendingChunks: sl<EmbedPendingChunksUseCase>(),
    ),
  );

  // Sync DIs
  sl.registerLazySingleton<ExpenseRemoteDataSource>(
    () => ExpenseRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      getUid: () => sl<fb.FirebaseAuth>().currentUser?.uid,
    ),
  );

  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => PushPendingChangesUseCase(sl<SyncRepository>()),
  );

  sl.registerLazySingleton(
    () => PullRemoteChangesUseCase(sl<SyncRepository>()),
  );

  sl.registerLazySingleton(
    () => WatchRemoteExpensesUseCase(sl<SyncRepository>()),
  );

  // Data Sources
  sl.registerLazySingleton<ExchangeRateRemoteDataSource>(
    () => ExchangeRateRemoteDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ExchangeRateLocalDataSource>(
    () => ExchangeRateLocalDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<CurrencyRepository>(
    () => CurrencyRepositoryImpl(remote: sl(), local: sl()),
  );

  // UseCases
  sl.registerLazySingleton(
    () => GetExchangeRatesUseCase(sl<CurrencyRepository>()),
  );

  sl.registerLazySingleton(
    () => ChangeCurrencyUseCase(sl<CurrencyRepository>()),
  );

  sl.registerLazySingleton(
    () => GetSelectedCurrencyUseCase(sl<CurrencyRepository>()),
  );

  sl.registerLazySingleton(
    () =>
        CreateCurrencyConverterUseCase((rates) => CurrencyConverterImpl(rates)),
  );

  // Cubit
  sl.registerFactory(
    () => CurrencyCubit(
      sl<UserSettingsRepository>(),
      getRates: sl<GetExchangeRatesUseCase>(),
      changeCurrencyUseCase: sl<ChangeCurrencyUseCase>(),
      getSelectedCurrencyUseCase: sl<GetSelectedCurrencyUseCase>(),
      createConverter: sl<CreateCurrencyConverterUseCase>(),
    ),
  );

  // Settings sync
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      getUid: () => sl<fb.FirebaseAuth>().currentUser?.uid,
    ),
  );

  sl.registerLazySingleton<UserSettingsRepository>(
    () => UserSettingsRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetUserSettingsUseCase(sl()));
  sl.registerLazySingleton(() => SyncUserSettingsUseCase(sl()));
  sl.registerLazySingleton(() => PullUserSettingsUseCase(sl()));

  // Budget DIs
  final budgetBox = Hive.box<BudgetModel>(HiveBoxes.budgets);
  sl.registerLazySingleton<Box<BudgetModel>>(() => budgetBox);

  sl.registerLazySingleton<BudgetLocalDataSource>(
    () => BudgetLocalDataSourceImpl(sl<Box<BudgetModel>>()),
  );

  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton(
    () => GetBudgetLimitsUseCase(repository: sl<BudgetRepository>()),
  );
  sl.registerLazySingleton(
    () => SetBudgetLimitsUseCase(repository: sl<BudgetRepository>()),
  );

  sl.registerLazySingleton(
    () => GetBudgetPeriodsUseCase(repository: sl<BudgetRepository>()),
  );

  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(
      firestore: sl<FirebaseFirestore>(),
      getUid: () => sl<fb.FirebaseAuth>().currentUser?.uid,
    ),
  );

  sl.registerLazySingleton<BudgetSyncRepository>(
    () => BudgetSyncRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton(() => PushBudgetChangesUseCase(sl()));
  sl.registerLazySingleton(() => PullBudgetChangesUseCase(sl()));
  sl.registerLazySingleton(() => WatchRemoteBudgetsUseCase(sl()));

  sl.registerFactory(
    () => BudgetLimitsBloc(
      getLimitsUseCase: sl<GetBudgetLimitsUseCase>(),
      getPeriodsUseCase: sl<GetBudgetPeriodsUseCase>(),
      setLimitsUseCase: sl<SetBudgetLimitsUseCase>(),
      pushBudgetChangesUseCase: sl<PushBudgetChangesUseCase>(),
      pullBudgetChangesUseCase: sl<PullBudgetChangesUseCase>(),
      watchRemoteBudgetsUseCase: sl<WatchRemoteBudgetsUseCase>(),
    ),
  );

  sl.registerFactory<ThemeCubit>(
    () => ThemeCubit(sl<UserSettingsRepository>()),
  );

  sl.registerFactory<LocaleCubit>(
    () => LocaleCubit(sl<UserSettingsRepository>()),
  );

  // Embedding DIs (TensorFlow Lite MiniLM)
  sl.registerLazySingleton<EmbeddingModelDataSource>(
    () => AssetEmbeddingModelDataSource(),
  );

  sl.registerLazySingleton<EmbeddingTokenizer>(
    () => MiniLmWordPieceTokenizer(sl<EmbeddingModelDataSource>()),
  );

  sl.registerLazySingleton<EmbeddingModel>(
    () => TfliteMiniLmEmbeddingModel(sl<EmbeddingModelDataSource>()),
  );

  sl.registerLazySingleton<EmbeddingRepository>(
    () => EmbeddingRepositoryImpl(
      tokenizer: sl<EmbeddingTokenizer>(),
      model: sl<EmbeddingModel>(),
    ),
  );

  sl.registerLazySingleton<EmbeddingService>(
    () => EmbeddingService.configure(sl<EmbeddingRepository>()),
  );

  sl.registerLazySingleton(
    () => GenerateEmbeddingUseCase(sl<EmbeddingRepository>()),
  );

  sl.registerLazySingleton(
    () => EmbedPendingChunksUseCase(
      chunkRepository: sl<EmbeddingChunkRepository>(),
      embeddingRepository: sl<EmbeddingRepository>(),
    ),
  );

  sl.registerLazySingleton(
    () => EmbedQueryUseCase(embeddingService: sl<EmbeddingService>()),
  );

  sl.registerLazySingleton<TopKRetriever>(
    () => TopKRetriever(chunkRepository: sl<EmbeddingChunkRepository>()),
  );

  // Retrieval fuses semantic (vector) and keyword (lexical) rankings. If the
  // MiniLM model is unavailable the lexical side carries on alone, so the
  // chat pipeline keeps working and the embedding failure stays invisible.
  sl.registerLazySingleton<VectorRetrievalService>(
    () => VectorRetrievalService(
      embeddingRepository: sl<EmbeddingRepository>(),
      topKRetriever: sl<TopKRetriever>(),
      chunkRepository: sl<EmbeddingChunkRepository>(),
      indexCache: VectorIndexCache(),
    ),
  );

  sl.registerLazySingleton(
    () => LexicalRetrievalService(
      chunkRepository: sl<EmbeddingChunkRepository>(),
    ),
  );

  sl.registerLazySingleton<RetrievalService>(
    () => HybridRetrievalService(
      vector: sl<VectorRetrievalService>(),
      lexical: sl<LexicalRetrievalService>(),
    ),
  );

  sl.registerLazySingleton<GemmaManager>(
    () => GemmaManagerImpl(
      config: const GemmaModelConfig(
        modelType: ModelType.qwen,
        defaultModelUrl:
            'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
      ),
    ),
  );

  sl.registerLazySingleton<ChatPromptBuilder>(
    () => const RagChatPromptBuilder(),
  );

  sl.registerLazySingleton<AiSafetyPolicy>(() => RuleBasedAiSafetyPolicy());

  sl.registerLazySingleton<DeviceCapability>(() => DeviceInfoCapability());
  sl.registerLazySingleton<AnswerStrategy>(
    () => AdaptiveAnswerStrategy(
      primary: GemmaAnswerStrategy(
        promptBuilder: sl<ChatPromptBuilder>(),
        gemma: sl<GemmaManager>(),
      ),
      fallback: const TemplateAnswerStrategy(),
      device: sl<DeviceCapability>(),
      onFallback: (reason) => AppLogBuffer.instance.captureError(
        'ai.liteMode',
        reason,
        StackTrace.current,
      ),
    ),
  );

  sl.registerLazySingleton(
    () => AnswerAffordabilityUseCase(
      insights: sl<GetBudgetInsightsUseCase>(),
      expenseRepository: sl<ExpenseRepository>(),
      goalRepository: sl<SavingsGoalRepository>(),
    ),
  );

  sl.registerLazySingleton(
    () => AskQuestionUseCase(
      retrievalService: sl<RetrievalService>(),
      answerStrategy: sl<AnswerStrategy>(),
      safetyPolicy: sl<AiSafetyPolicy>(),
      directAnswer: sl<AnswerAffordabilityUseCase>().call,
    ),
  );

  // Lazy singleton: the conversation survives navigation away from and back
  // to the chat screen, but is rebuilt fresh on app restart.
  sl.registerLazySingleton(
    () => ChatBloc(
      askQuestion: sl<AskQuestionUseCase>(),
      embedPendingChunks: sl<EmbedPendingChunksUseCase>(),
      buildChart: BuildAnswerChartUseCase(
        expenseRepository: sl<ExpenseRepository>(),
        budgetInsights: sl<GetBudgetInsightsUseCase>(),
        categoryNames: _categoryNamesForCharts,
      ),
    ),
  );

  // Notifications DIs
  final notificationsBox = Hive.box<AppNotificationModel>(
    HiveBoxes.notifications,
  );
  sl.registerLazySingleton<Box<AppNotificationModel>>(() => notificationsBox);

  sl.registerLazySingleton<NotificationLocalDataSource>(
    () => NotificationLocalDataSourceImpl(sl<Box<AppNotificationModel>>()),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl<NotificationLocalDataSource>()),
  );

  sl.registerLazySingleton(
    () => SaveNotificationUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton(
    () => WatchNotificationsUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton(
    () => MarkNotificationReadUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton(
    () => MarkAllNotificationsReadUseCase(sl<NotificationRepository>()),
  );
  sl.registerLazySingleton(
    () => ClearNotificationsUseCase(sl<NotificationRepository>()),
  );

  sl.registerFactory(
    () => NotificationsCubit(
      watchNotifications: sl<WatchNotificationsUseCase>(),
      markRead: sl<MarkNotificationReadUseCase>(),
      markAllRead: sl<MarkAllNotificationsReadUseCase>(),
      clear: sl<ClearNotificationsUseCase>(),
    ),
  );

  // FCM token DIs
  sl.registerLazySingleton<FcmTokenDataSource>(
    () => FcmTokenDataSourceImpl(sl<FirebaseFirestore>()),
  );

  sl.registerLazySingleton<FcmTokenRepository>(
    () => FcmTokenRepositoryImpl(
      dataSource: sl<FcmTokenDataSource>(),
      firebaseAuth: sl<fb.FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton(() => SaveFcmTokenUseCase(sl<FcmTokenRepository>()));

  // FCM push service
  sl.registerLazySingleton(
    () => FcmPushService(
      FirebaseMessaging.instance,
      sl<fb.FirebaseAuth>(),
      saveFcmToken: sl<SaveFcmTokenUseCase>(),
      saveNotification: sl<SaveNotificationUseCase>(),
      localNotifications: sl<LocalNotificationService>(),
    ),
  );

  // Local notifications DIs
  sl.registerLazySingleton(() => LocalNotificationService());

  sl.registerLazySingleton<BudgetAlertEvaluator>(
    () => const BudgetAlertEvaluator(),
  );

  sl.registerLazySingleton<Box<dynamic>>(
    () => Hive.box<dynamic>(HiveBoxes.notificationState),
  );

  sl.registerLazySingleton<NotificationSettingsLocalDataSource>(
    () => NotificationSettingsLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<NotificationSettingsRepository>(
    () => NotificationSettingsRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetNotificationSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateNotificationSettingsUseCase(sl()));

  sl.registerFactory(
    () => NotificationSettingsCubit(
      getSettings: sl<GetNotificationSettingsUseCase>(),
      updateSettings: sl<UpdateNotificationSettingsUseCase>(),
      onReschedule: () => sl<NotificationScheduler>().scheduleAll(),
    ),
  );

  sl.registerLazySingleton(
    () => BudgetAlertWatcher(
      notifications: sl<LocalNotificationService>(),
      expenseBox: sl<Box<ExpenseModel>>(),
      budgetRepository: sl<BudgetRepository>(),
      stateBox: sl<Box<dynamic>>(),
      settingsRepository: sl<NotificationSettingsRepository>(),
      rolloverRepository: sl<BudgetRolloverRepository>(),
      budgetFilter: sl<BudgetExpenseFilter>(),
      envelopes: sl<EnvelopeAdjustments>(),
      evaluator: sl<BudgetAlertEvaluator>(),
    ),
  );

  sl.registerLazySingleton(
    () => GenerateWeeklyDigestUseCase(
      expenseRepository: sl<ExpenseRepository>(),
      budgetRepository: sl<BudgetRepository>(),
      recurringRepository: sl<RecurringExpenseRepository>(),
      writer: GemmaDigestWriter(
        gemma: sl<GemmaManager>(),
        device: sl<DeviceCapability>(),
      ),
      cache: HiveDigestCache(Hive.box<dynamic>(HiveBoxes.settings)),
      rolloverRepository: sl<BudgetRolloverRepository>(),
      budgetFilter: sl<BudgetExpenseFilter>(),
    ),
  );

  sl.registerLazySingleton(
    () => NotificationScheduler(
      notifications: sl<LocalNotificationService>(),
      expenseRepository: sl<ExpenseRepository>(),
      settingsRepository: sl<NotificationSettingsRepository>(),
      recurringRepository: sl<RecurringExpenseRepository>(),
      weeklyDigest: sl<GenerateWeeklyDigestUseCase>(),
    ),
  );

  sl.registerLazySingleton(
    () => CaptureNotificationService(
      notifications: sl<LocalNotificationService>(),
      settingsRepository: sl<NotificationSettingsRepository>(),
    ),
  );

  // Voice expense entry
  sl.registerLazySingleton<SpeechRecognizer>(() => SpeechToTextRecognizer());
  sl.registerLazySingleton(
    () => ParseVoiceExpenseUseCase(
      expenseRepository: sl<ExpenseRepository>(),
      refiner: GemmaVoiceExpenseRefiner(
        gemma: sl<GemmaManager>(),
        device: sl<DeviceCapability>(),
      ),
    ),
  );
  sl.registerFactoryParam<VoiceEntryCubit, String, List<String>>(
    (localeId, categoryIds) => VoiceEntryCubit(
      recognizer: sl<SpeechRecognizer>(),
      parse: sl<ParseVoiceExpenseUseCase>(),
      categoryIds: categoryIds,
      localeId: localeId,
    ),
  );

  sl.registerLazySingleton(
    () => WeeklyDigestService(
      generate: sl<GenerateWeeklyDigestUseCase>(),
      scheduler: sl<NotificationScheduler>(),
      saveNotification: sl<SaveNotificationUseCase>(),
      stateBox: sl<Box<dynamic>>(),
    ),
  );
}

/// Defers to [CaptureNotificationService] at call time so registration order
/// between the SMS and notification sections doesn't matter.
class _LazyCaptureNotifier implements CaptureNotifier {
  @override
  Future<void> notify(List<CapturedTransaction> captures) =>
      sl<CaptureNotificationService>().notify(captures);
}

/// Category id → every name a user might type for it, in all app languages.
Map<String, List<String>> _categoryNamesForCharts() {
  final locales = [
    for (final code in ['en', 'hi', 'mr']) lookupAppLocalizations(Locale(code)),
  ];
  return {
    for (final c in ExpenseCategories.all)
      c.id: {
        c.id,
        c.label,
        for (final l10n in locales) c.labelOf(l10n),
      }.toList(),
  };
}
