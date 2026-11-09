/// Single source of truth for every Hive box name used by the app.
///
/// [SecureHive] opens all of these encrypted at startup, so any later
/// `Hive.openBox(name)` / `Hive.box(name)` call returns the already-open,
/// encrypted instance instead of creating a plaintext one.
abstract final class HiveBoxes {
  static const expenses = 'expense_box';
  static const budgets = 'budget_box';
  static const recurringExpenses = 'recurring_expense_box';
  static const aiEmbeddings = 'ai_embeddings_box';
  static const aiDisclaimer = 'ai_disclaimer_box';
  static const notifications = 'notifications_box';
  static const notificationState = 'notification_state_box';
  static const notificationSettings = 'notification_settings_box';
  static const settings = 'settings';
  static const exchangeRates = 'exchange_rates';
  static const customCategories = 'custom_categories';
  static const savingsGoals = 'savings_goals';
  static const capturedTransactions = 'captured_transactions';
  static const spendingEvents = 'spending_events';

  /// Unencrypted bookkeeping box. Holds only migration flags, never user data.
  static const meta = 'hive_meta';
}
