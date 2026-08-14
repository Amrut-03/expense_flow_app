// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ExpenseFlow';

  @override
  String get appTagline => 'Track. Budget. Breathe.';

  @override
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_next => 'Next';

  @override
  String get onboarding_getStarted => 'Get started';

  @override
  String get onboarding_slide1Title => 'Track every expense';

  @override
  String get onboarding_slide1Subtitle =>
      'Log any expense in seconds with smart categories and handy notes.';

  @override
  String get onboarding_slide2Title => 'Budgets that keep you on track';

  @override
  String get onboarding_slide2Subtitle =>
      'Set monthly limits and see exactly where your money goes.';

  @override
  String get onboarding_slide3Title => 'Insights that help you breathe easy';

  @override
  String get onboarding_slide3Subtitle =>
      'Understand your spending with clear insights and smart goals.';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_google => 'Google';

  @override
  String get common_apple => 'Apple';

  @override
  String get common_language => 'Language';

  @override
  String get common_settings => 'Settings';

  @override
  String get common_loading => 'Loading';

  @override
  String get common_somethingWentWrong => 'Something went wrong';

  @override
  String get auth_createAccount => 'Create account';

  @override
  String get auth_signupSubtitle => 'Start tracking your expenses in seconds';

  @override
  String get auth_fullName => 'Full name';

  @override
  String get auth_nameRequired => 'Name is required';

  @override
  String get auth_emailAddress => 'Email address';

  @override
  String get auth_emailRequired => 'Email is required';

  @override
  String get auth_invalidEmail => 'Enter a valid email';

  @override
  String get auth_password => 'Password';

  @override
  String get auth_passwordRequired => 'Password is required';

  @override
  String get auth_passwordMinChars => 'Minimum 6 characters';

  @override
  String get auth_passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get auth_confirmPassword => 'Confirm password';

  @override
  String get auth_confirmPasswordRequired => 'Confirm your password';

  @override
  String get auth_orContinueWith => 'or continue with';

  @override
  String get auth_alreadyHaveAccount => 'Already have an account? ';

  @override
  String get auth_logIn => 'Log in';

  @override
  String get auth_welcomeBack => 'Welcome back';

  @override
  String get auth_loginSubtitle => 'Log in to keep tracking your spending';

  @override
  String get auth_forgotPassword => 'Forgot password?';

  @override
  String get auth_forgotPasswordTitle => 'Forgot Password';

  @override
  String get auth_forgotPasswordSubtitle =>
      'Enter your email and we will send you a link to reset your password';

  @override
  String get auth_sendResetLink => 'Send reset link';

  @override
  String get auth_passwordResetSent => 'Password reset email sent.';

  @override
  String get auth_dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get auth_signUp => 'Sign up';

  @override
  String get auth_logOut => 'Log out';

  @override
  String get auth_logOutQuestion => 'Log out?';

  @override
  String get auth_logOutSubtitle =>
      'You will need to sign in again to access your data.';

  @override
  String get auth_profileUpdated => 'Profile updated';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_darkMode => 'Dark mode';

  @override
  String get settings_notifications => 'Notifications';

  @override
  String get settings_currency => 'Currency';

  @override
  String get settings_exportData => 'Export data';

  @override
  String get settings_editName => 'Edit name';

  @override
  String get settings_editNameSubtitle =>
      'This name is shown on your profile and saved to your account';

  @override
  String get settings_yourName => 'Your name';

  @override
  String get settings_nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get settings_changeCurrency => 'Change Currency';

  @override
  String get settings_chooseCurrency => 'Choose your preferred currency';

  @override
  String get settings_logReport => 'Log report';

  @override
  String get settings_logReportGenerating => 'Generating log report…';

  @override
  String get settings_logReportReady => 'Log report ready';

  @override
  String get settings_logReportFailed => 'Failed to create log report';

  @override
  String get language_title => 'Change Language';

  @override
  String get language_choose => 'Choose your preferred language';

  @override
  String get dashboard_goodMorning => 'Good Morning';

  @override
  String get dashboard_goodAfternoon => 'Good Afternoon';

  @override
  String get dashboard_goodEvening => 'Good Evening';

  @override
  String get dashboard_goodNight => 'Good Night';

  @override
  String get dashboard_totalSpentThisMonth => 'Total spent this month';

  @override
  String get dashboard_categories => 'Categories';

  @override
  String get dashboard_recent => 'Recent';

  @override
  String get dashboard_noTransactionsToday => 'No transactions today';

  @override
  String get dashboard_spendingBreakdown => 'Spending breakdown';

  @override
  String get dashboard_monthlyTrend => 'Monthly trend';

  @override
  String get addExpense_title => 'Add Expense';

  @override
  String get addExpense_validAmount => 'Please enter a valid amount';

  @override
  String get addExpense_selectCategory => 'Please select a category';

  @override
  String get addExpense_titleRequired => 'Title is required';

  @override
  String get addExpense_selectPaymentMethod => 'Please select a payment method';

  @override
  String get addExpense_added => 'Expense added successfully';

  @override
  String get addExpense_titleLabel => 'Title*';

  @override
  String get addExpense_expenseTitle => 'Expense title';

  @override
  String get addExpense_categoryLabel => 'Category*';

  @override
  String get addExpense_paymentMethodLabel => 'Payment method*';

  @override
  String get addExpense_note => 'Note';

  @override
  String get addExpense_noteHint => 'Add Note (Optional)';

  @override
  String get editExpense_title => 'Edit transaction';

  @override
  String get editExpense_updated => 'Expense updated successfully';

  @override
  String get editExpense_deleted => 'Expense deleted successfully';

  @override
  String get detail_transactionDetails => 'Transaction Details';

  @override
  String get detail_deleteTransaction => 'Delete transaction';

  @override
  String get detail_deleteConfirm =>
      'Are you sure you want to delete this transaction?';

  @override
  String get detail_date => 'Date';

  @override
  String get detail_category => 'Category';

  @override
  String get detail_paymentMethod => 'Payment method';

  @override
  String get detail_currency => 'Currency';

  @override
  String get detail_noNote => 'No note added.';

  @override
  String get budget_title => 'Budget';

  @override
  String get budget_totalSpentThisMonth => 'Total spent this month';

  @override
  String get budget_noExpensesYet => 'No expenses yet';

  @override
  String get budget_setFirstBudget => 'Set your first budget';

  @override
  String get budget_setFirstBudgetSubtitle =>
      'Give each category a monthly limit so you can see where your money is going and stay on track.';

  @override
  String get budget_createYourBudget => 'Create your budget';

  @override
  String get budget_skipForNow => 'Skip for now';

  @override
  String get budget_notifiedBeforeOverspend =>
      'Get notified before you overspend';

  @override
  String get budget_spendingTrends => 'See spending trends by category';

  @override
  String get budget_editBudgets => 'Edit budgets';

  @override
  String get budget_createBudget => 'Create budget';

  @override
  String get budget_createHint =>
      'Set a monthly limit for each category. You can change these anytime.';

  @override
  String get budget_totalMonthlyBudget => 'Total monthly budget';

  @override
  String get budget_periodMonthly => 'Monthly';

  @override
  String get budget_periodQuarterly => 'Quarterly';

  @override
  String get budget_periodYearly => 'Yearly';

  @override
  String get budget_periodNoLimit => 'No limit';

  @override
  String budget_percentUsed(String percent) {
    return '$percent% used';
  }

  @override
  String get budget_spendingBreakdown => 'Spending breakdown';

  @override
  String get budget_others => 'Others';

  @override
  String budget_spentAmount(String amount) {
    return '$amount spent';
  }

  @override
  String budget_ofAmount(String amount) {
    return 'of $amount';
  }

  @override
  String get notifications_title => 'Notifications';

  @override
  String get notifications_allCaughtUp => 'All caught up';

  @override
  String get notifications_none => 'You have no new notifications.';

  @override
  String get notifications_budgetLimitReached => 'Budget limit reached';

  @override
  String get notifications_budgetLimitMsg =>
      'You have used 80% of your Shopping budget this month.';

  @override
  String get notifications_dataSynced => 'Data synced';

  @override
  String get notifications_dataSyncedMsg =>
      'Your expenses were successfully synced to the cloud.';

  @override
  String get notifications_spendingInsight => 'Spending insight';

  @override
  String get notifications_spendingInsightMsg =>
      'Your entertainment spending is 15% lower than last month.';

  @override
  String get notifications_twoHoursAgo => '2h ago';

  @override
  String get notifications_yesterday => 'Yesterday';

  @override
  String get notifications_twoDaysAgo => '2 days ago';

  @override
  String get category_food => 'Food';

  @override
  String get category_bills => 'Bills';

  @override
  String get category_shopping => 'Shopping';

  @override
  String get category_transport => 'Transport';

  @override
  String get category_entertainment => 'Entertainment';

  @override
  String get category_health => 'Health';

  @override
  String get category_travel => 'Travel';

  @override
  String get category_education => 'Education';

  @override
  String get category_other => 'Other';

  @override
  String get payment_cash => 'Cash';

  @override
  String get payment_card => 'Card';

  @override
  String get payment_upi => 'UPI';

  @override
  String get payment_bankTransfer => 'Bank Transfer';

  @override
  String get payment_other => 'Other';

  @override
  String sync_savedLocalNotSynced(String message) {
    return 'Saved locally. Not synced: $message';
  }

  @override
  String sync_showingSavedData(String message) {
    return 'Showing saved data. Refresh failed: $message';
  }

  @override
  String sync_liveSyncFailed(String message) {
    return 'Live sync failed: $message';
  }

  @override
  String get sync_ratesUnavailable =>
      'Live exchange rates are unavailable. Amounts are shown in INR.';

  @override
  String get error_default => 'Something went wrong.';

  @override
  String get error_noConnection =>
      'Could not reach the server. Check your connection.';

  @override
  String get error_timeout => 'The request timed out. Please try again.';

  @override
  String get error_invalidData =>
      'The data received was invalid. Please try again.';

  @override
  String error_serverError(String status) {
    return 'Server error ($status). Please try again later.';
  }

  @override
  String get transaction_searchHint => '🔍 Search Transactions';

  @override
  String get transaction_newest => 'Newest';

  @override
  String get transaction_oldest => 'Oldest';

  @override
  String get transaction_highestAmount => 'Highest Amount';

  @override
  String get transaction_lowestAmount => 'Lowest Amount';

  @override
  String get transaction_today => 'Today';

  @override
  String get transaction_yesterday => 'Yesterday';
}
