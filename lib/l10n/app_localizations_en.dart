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

  @override
  String get addExpense_merchantLabel => 'Merchant (optional)';

  @override
  String get addExpense_merchantHint => 'e.g. Swiggy, Amazon, D-Mart';

  @override
  String get addExpense_repeatLabel => 'Repeat';

  @override
  String get recurrence_none => 'Never';

  @override
  String get recurrence_daily => 'Daily';

  @override
  String get recurrence_weekly => 'Weekly';

  @override
  String get recurrence_monthly => 'Monthly';

  @override
  String get recurrence_yearly => 'Yearly';

  @override
  String get detail_merchant => 'Merchant';

  @override
  String get detail_paidAmount => 'Paid amount';

  @override
  String get detail_recurring => 'Recurring';

  @override
  String get recurring_title => 'Recurring expenses';

  @override
  String get recurring_emptyTitle => 'No recurring expenses';

  @override
  String get recurring_emptyHint =>
      'Pick a Repeat option when adding an expense to log rent, EMIs or subscriptions automatically.';

  @override
  String recurring_nextDue(String date) {
    return 'Next: $date';
  }

  @override
  String get recurring_paused => 'Paused';

  @override
  String get recurring_deleteTitle => 'Delete recurring expense?';

  @override
  String get recurring_deleteMessage =>
      'No new entries will be created. Expenses already logged are kept.';

  @override
  String get settings_recurring => 'Recurring expenses';

  @override
  String get settings_appLock => 'App lock';

  @override
  String get appLock_lockedTitle => 'ExpenseFlow is locked';

  @override
  String get appLock_lockedSubtitle => 'Unlock to see your expenses';

  @override
  String get appLock_unlock => 'Unlock';

  @override
  String get appLock_reason => 'Unlock ExpenseFlow';

  @override
  String get appLock_failed => 'Couldn\'t verify it\'s you. Try again.';

  @override
  String get appLock_lockedOut =>
      'Too many attempts. Try again in a little while.';

  @override
  String get appLock_enableReason => 'Confirm to turn on app lock';

  @override
  String get appLock_disableReason => 'Confirm to turn off app lock';

  @override
  String get appLock_unavailable =>
      'Set up a screen lock or fingerprint on your device first.';

  @override
  String get addExpense_categorySuggested => '✨ Suggested';

  @override
  String budget_paceAtRisk(String date) {
    return 'At this pace, runs out around $date';
  }

  @override
  String budget_paceExceeded(String amount) {
    return 'Over budget by $amount';
  }

  @override
  String budget_paceOnTrack(String amount, int days) {
    return 'On track · $amount/day for $days days';
  }

  @override
  String get capture_add => 'Add';

  @override
  String capture_banner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments found in your SMS',
      one: '1 payment found in your SMS',
    );
    return '$_temp0';
  }

  @override
  String get capture_defaultTitle => 'Payment';

  @override
  String get capture_dismiss => 'Dismiss';

  @override
  String get capture_emptyHint =>
      'New bank and UPI payments will show up here for you to confirm.';

  @override
  String get capture_emptyTitle => 'All caught up';

  @override
  String get capture_possibleDuplicate => 'You may have already logged this';

  @override
  String get capture_review => 'Review';

  @override
  String get capture_showSms => 'Show SMS';

  @override
  String get capture_title => 'Detected payments';

  @override
  String get capture_tooLarge =>
      'This amount is above the per-expense limit. Add it manually.';

  @override
  String get capture_unknownMerchant => 'Unknown payee';

  @override
  String get categories_add => 'New category';

  @override
  String get categories_archiveMessage =>
      'It will be hidden from pickers. Expenses already in it keep their category.';

  @override
  String categories_archiveTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get categories_builtIn => 'Built-in';

  @override
  String get categories_colorLabel => 'Colour';

  @override
  String get categories_editTitle => 'Edit category';

  @override
  String get categories_emptyHint => 'Add your own, like Rent, Kirana or Maid.';

  @override
  String get categories_errorDuplicate =>
      'A category with this name already exists';

  @override
  String get categories_errorEmpty => 'Enter a name';

  @override
  String get categories_errorTooLong => 'Name is too long';

  @override
  String get categories_errorTooMany => 'You\'ve reached the category limit';

  @override
  String get categories_iconLabel => 'Icon';

  @override
  String get categories_nameHint => 'e.g. Rent, Kirana, Pet care';

  @override
  String get categories_nameLabel => 'Name';

  @override
  String get categories_newTitle => 'New category';

  @override
  String get categories_title => 'Categories';

  @override
  String get categories_yours => 'Your categories';

  @override
  String get goals_addMoney => 'Add money';

  @override
  String get goals_amountHint => 'Amount';

  @override
  String goals_by(String date) {
    return 'By $date';
  }

  @override
  String get goals_complete => 'Goal reached 🎉';

  @override
  String get goals_delete => 'Delete goal';

  @override
  String get goals_emptyHint =>
      'Save towards a trip, a phone or an emergency fund and see how much to set aside each day.';

  @override
  String get goals_emptyTitle => 'No savings goals yet';

  @override
  String get goals_initialLabel => 'Already saved (optional)';

  @override
  String get goals_nameHint => 'e.g. Goa trip';

  @override
  String get goals_new => 'New goal';

  @override
  String get goals_overdue => 'Target date has passed';

  @override
  String goals_perDay(String amount, int days) {
    return 'Save $amount/day · $days days left';
  }

  @override
  String get goals_pickDate => 'Set a target date (optional)';

  @override
  String goals_remaining(String amount) {
    return '$amount to go';
  }

  @override
  String goals_savedOf(String saved, String target) {
    return '$saved of $target';
  }

  @override
  String goals_targetLabel(String symbol) {
    return 'Target ($symbol)';
  }

  @override
  String get goals_title => 'Savings goals';

  @override
  String get goals_withdraw => 'Withdraw';

  @override
  String safeToSpend_afterBills(String amount) {
    return 'After setting aside $amount for upcoming bills';
  }

  @override
  String get safeToSpend_basedOnBudgets =>
      'Based on what\'s left in your budgets';

  @override
  String safeToSpend_overBudget(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budgets are over their limit',
      one: '1 budget is over its limit',
    );
    return '$_temp0';
  }

  @override
  String get safeToSpend_setBudgetHint =>
      'Set a budget to see how much you can safely spend each day';

  @override
  String get safeToSpend_title => 'Safe to spend today';

  @override
  String get settings_categories => 'Categories';

  @override
  String get settings_goals => 'Savings goals';

  @override
  String get settings_smsCapture => 'Detect payments from SMS';

  @override
  String get settings_subscriptions => 'Subscriptions';

  @override
  String get sms_disclosureAccept => 'Allow';

  @override
  String get sms_disclosureBody =>
      'ExpenseFlow reads bank and UPI SMS on this phone to find your payments. Messages are processed only on your device and are never uploaded or shared. You review every payment before it is saved. You can turn this off any time in Settings.';

  @override
  String get sms_disclosureDecline => 'Not now';

  @override
  String get sms_disclosureTitle => 'Detect payments from SMS?';

  @override
  String get sms_permissionDenied =>
      'SMS permission is needed. You can allow it in system settings.';

  @override
  String get subscriptions_emptyHint =>
      'When a merchant charges you a similar amount every week, month or year, it shows up here.';

  @override
  String get subscriptions_emptyTitle => 'No subscriptions found yet';

  @override
  String get subscriptions_monthlyTotal =>
      'You spend about this much per month on subscriptions';

  @override
  String subscriptions_nextCharge(String date, String yearly) {
    return 'Next charge $date · $yearly/year';
  }

  @override
  String get subscriptions_title => 'Subscriptions';

  @override
  String get subscriptions_track => 'Auto-log';

  @override
  String get subscriptions_tracked => 'Auto-logged';

  @override
  String subscriptions_trackedMessage(String name) {
    return '$name will now be logged automatically';
  }

  @override
  String subscriptions_yearlyTotal(String amount) {
    return '$amount per year';
  }

  @override
  String get dashboard_paymentMethods => 'Payment methods';

  @override
  String get dashboard_spendCalendar => 'Spending calendar';

  @override
  String get insights_noSpendThisMonth => 'No spending logged this month yet.';

  @override
  String insights_digitalShare(String percent) {
    return '$percent% paid digitally this month';
  }

  @override
  String insights_digitalUp(String points) {
    return '▲ $points pts vs last month';
  }

  @override
  String insights_digitalDown(String points) {
    return '▼ $points pts vs last month';
  }

  @override
  String streak_current(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day no-spend streak',
      one: '1-day no-spend streak',
      zero: 'No no-spend streak right now',
    );
    return '$_temp0';
  }

  @override
  String streak_monthSummary(int count, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count no-spend days',
      one: '1 no-spend day',
    );
    return '$_temp0 this month · best run $best';
  }

  @override
  String get calendar_noSpend => 'no spending';

  @override
  String get notif_billReminders => 'Bill & EMI reminders';

  @override
  String get tax_label => 'Tax deduction';

  @override
  String get tax_none => 'None';

  @override
  String get tax_desc80C => 'LIC, PPF, ELSS, tuition fees, home-loan principal';

  @override
  String get tax_desc80D =>
      'Health insurance premiums and preventive check-ups';

  @override
  String get tax_descHra =>
      'House rent paid (exempt amount depends on salary and city)';

  @override
  String get tax_desc80G => 'Donations to eligible charities';

  @override
  String get tax_desc80E => 'Interest on an education loan';

  @override
  String get tax_summaryTitle => 'Tax deductions';

  @override
  String get settings_taxSummary => 'Tax deductions';

  @override
  String get tax_totalClaimable => 'Estimated deductible amount';

  @override
  String get tax_oldRegimeNote =>
      'Applies under the old tax regime. Guidance only, not tax advice.';

  @override
  String get tax_emptyTitle => 'No tax-tagged expenses';

  @override
  String get tax_emptyHint =>
      'Tag rent, insurance, school fees or donations when you add them to see your yearly deduction summary here.';

  @override
  String tax_capUsed(String claimable, String cap) {
    return '$claimable of $cap limit used';
  }

  @override
  String tax_capRemaining(String amount) {
    return '$amount more can still be claimed';
  }

  @override
  String get tax_noCap => 'No fixed limit';

  @override
  String tax_expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String get detail_taxTag => 'Tax section';

  @override
  String get export_share => 'Share';

  @override
  String get rollover_title => 'Unspent budget';

  @override
  String get rollover_hint =>
      'What happens to money left over when this budget period ends.';

  @override
  String get rollover_rowLabel => 'Rollover';

  @override
  String get rollover_off => 'Off';

  @override
  String get rollover_offHint => 'Unspent money simply expires';

  @override
  String get rollover_carryForward => 'Carry forward';

  @override
  String get rollover_carryForwardHint =>
      'Add last period\'s unspent amount to this period\'s limit';

  @override
  String get rollover_toGoalShort => 'To savings goal';

  @override
  String rollover_toGoalNamed(String goal) {
    return 'Save into $goal';
  }

  @override
  String get rollover_toGoalHint =>
      'Unspent amount is added to this goal when each period ends';

  @override
  String get rollover_noGoals =>
      'Create a savings goal to move unspent budget into it.';

  @override
  String rollover_includes(String amount) {
    return 'Includes $amount rolled over';
  }

  @override
  String get settings_reports => 'Statements & export';

  @override
  String get reports_title => 'Statements & export';

  @override
  String get reports_statementTitle => 'Monthly statement';

  @override
  String get reports_statementHint =>
      'A PDF with totals, category and payment-method breakdown, and every transaction.';

  @override
  String get reports_noExpensesMonth => 'No expenses this month';

  @override
  String get reports_total => 'Total';

  @override
  String get reports_transactions => 'Transactions';

  @override
  String get reports_topCategory => 'Top category';

  @override
  String get reports_sharePdf => 'Share PDF';

  @override
  String get reports_csvTitle => 'Export to Excel (CSV)';

  @override
  String get reports_csvHint => 'Opens in Excel, Google Sheets or Numbers.';

  @override
  String get reports_rangeThisMonth => 'This month';

  @override
  String get reports_rangeLastMonth => 'Last month';

  @override
  String get reports_rangeFinancialYear => 'This financial year';

  @override
  String get reports_rangeAllTime => 'All time';

  @override
  String get reports_exportCsv => 'Export CSV';

  @override
  String get reports_taxLink => 'Tax deduction summary';

  @override
  String get reports_privacyNote =>
      'Files are created on your phone. Nothing is uploaded unless you share it.';

  @override
  String get export_nothing => 'Nothing to export for this period';

  @override
  String get export_failed => 'Couldn\'t create the file. Please try again.';

  @override
  String get notif_captureAlerts => 'Detected payments';

  @override
  String capture_loggedFromNotification(String amount, String category) {
    return 'Logged $amount as $category';
  }

  @override
  String get voice_title => 'Speak your expense';

  @override
  String get voice_tapToSpeak => 'Tap the mic and speak';

  @override
  String get voice_listening => 'Listening…';

  @override
  String get voice_examples =>
      'Try “चहा 20 रुपये”, “petrol 500 cash” or “Swiggy 250 UPI”. Recognised on your phone.';

  @override
  String get voice_onlineNote =>
      'Online recognition: your voice is sent to the device\'s speech service (e.g. Google). Expense data stays on your phone.';

  @override
  String get voice_useOnline => 'Use online recognition';

  @override
  String get voice_permissionDenied =>
      'Microphone permission is needed for voice entry. Enable it in Settings.';

  @override
  String get voice_unavailable =>
      'Speech recognition isn\'t available on this device.';

  @override
  String get voice_offlineUnavailable =>
      'Offline speech for this language isn\'t installed. Download it in your phone\'s speech settings, or use online recognition.';

  @override
  String get voice_needsInternet =>
      'Couldn\'t reach the speech service. Check your internet connection.';

  @override
  String get voice_noMatch => 'Didn\'t catch that. Tap the mic and try again.';

  @override
  String get voice_failed => 'Something went wrong. Please try again.';

  @override
  String voice_filled(String transcript) {
    return 'Filled from “$transcript”. Check and save.';
  }

  @override
  String get voice_button => 'Add by voice';

  @override
  String get notif_loggingReminder => 'Logging reminder';

  @override
  String notif_loggingLearned(String time) {
    return 'At your usual logging time, around $time. Skipped on days you\'ve already logged.';
  }

  @override
  String notif_loggingDefault(String time) {
    return 'At $time for now. It moves to your usual logging time once ExpenseFlow learns it.';
  }

  @override
  String get events_title => 'Events & trips';

  @override
  String get events_settingsTile => 'Events & trips';

  @override
  String get events_new => 'New event';

  @override
  String get events_edit => 'Edit';

  @override
  String get events_delete => 'Delete';

  @override
  String get events_deleteConfirm =>
      'Delete this event? Its expenses are kept and count towards your monthly budgets again.';

  @override
  String get events_save => 'Save';

  @override
  String get events_emptyTitle => 'Plan for big occasions';

  @override
  String get events_emptyHint =>
      'Give Diwali, a wedding or a trip its own budget across categories. Trips can use their own currency.';

  @override
  String get events_kindFestival => 'Festival';

  @override
  String get events_kindWedding => 'Wedding';

  @override
  String get events_kindTrip => 'Trip';

  @override
  String get events_kindOther => 'Other';

  @override
  String get events_nameHint => 'Name, e.g. Diwali 2026';

  @override
  String get events_nameHintTrip => 'Name, e.g. Bangkok trip';

  @override
  String events_budgetHint(String symbol) {
    return 'Budget ($symbol)';
  }

  @override
  String events_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String events_daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: 'last day',
    );
    return '$_temp0';
  }

  @override
  String events_starts(String date) {
    return 'starts $date';
  }

  @override
  String events_ended(String date) {
    return 'ended $date';
  }

  @override
  String get events_tripCurrency => 'Trip currency';

  @override
  String get events_tripCurrencyHint =>
      'While the trip is on, new expenses are entered in this currency and converted at the live rate.';

  @override
  String get events_categories => 'Suggest for categories';

  @override
  String get events_allCategories => 'All';

  @override
  String get events_separate => 'Keep out of monthly budgets';

  @override
  String get events_separateHint =>
      'This spending has its own budget here, so it won\'t use up your category budgets.';

  @override
  String get events_separateNote =>
      'Kept out of your monthly category budgets.';

  @override
  String events_spentOf(String spent, String budget) {
    return '$spent of $budget';
  }

  @override
  String events_perDayLeft(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'the next $count days',
      one: 'today',
    );
    return '$amount/day for $_temp0';
  }

  @override
  String events_over(String amount) {
    return '$amount over budget';
  }

  @override
  String events_projectedOver(String amount) {
    return 'At this pace you\'ll spend $amount';
  }

  @override
  String get events_byCategory => 'By category';

  @override
  String events_transactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get events_noTransactions =>
      'Nothing yet. Expenses you add while this is on are tagged automatically.';

  @override
  String get events_errorName => 'Enter a name (up to 40 characters).';

  @override
  String get events_errorDates =>
      'The end date must be on or after the start, within a year.';

  @override
  String get events_partOf => 'Part of';

  @override
  String get events_autoSelected => 'auto-selected';

  @override
  String get events_none => 'None';

  @override
  String events_noRate(String code) {
    return 'No exchange rate for $code yet. Connect to the internet once, or pick None to enter it in your usual currency.';
  }

  @override
  String get events_dashboardTitle => 'Happening now';

  @override
  String get envelopes_title => 'Envelope budgeting';

  @override
  String get envelopes_introTitle => 'Give every rupee a job';

  @override
  String get envelopes_intro1 =>
      'Tell ExpenseFlow how much you earn this month, then split all of it across your category budgets (envelopes) until nothing is left to assign.';

  @override
  String get envelopes_intro2 =>
      'What\'s left in an envelope carries into next month, and overspending does too.';

  @override
  String get envelopes_intro3 =>
      'Overspent? Move money from another envelope to cover it.';

  @override
  String get envelopes_introNote =>
      'Uses your monthly category budgets. Weekly, quarterly and yearly budgets aren\'t envelopes. Replaces rollover settings while on.';

  @override
  String get envelopes_turnOn => 'Turn on envelope mode';

  @override
  String get envelopes_turnOff => 'Turn off envelope mode';

  @override
  String get envelopes_toBeAssigned => 'To be assigned';

  @override
  String get envelopes_setIncomePrompt => 'Set this month\'s income to start.';

  @override
  String get envelopes_allAssigned => 'Every rupee has a job. 🎉';

  @override
  String envelopes_assignRest(String amount) {
    return 'Assign $amount more to your envelopes.';
  }

  @override
  String envelopes_overAssigned(String amount) {
    return 'You\'ve assigned $amount more than you earn. Lower some envelopes.';
  }

  @override
  String envelopes_income(String amount) {
    return 'Income this month: $amount';
  }

  @override
  String get envelopes_noIncome => 'No income set';

  @override
  String get envelopes_setIncome => 'Set income';

  @override
  String get envelopes_incomeHint =>
      'Money you\'ll have this month, e.g. salary. Used for future months until you change it.';

  @override
  String get envelopes_editAllocations => 'Adjust envelope amounts';

  @override
  String envelopes_overspentWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count envelopes are overspent.',
      one: '1 envelope is overspent.',
    );
    return '$_temp0 Tap it to move money in.';
  }

  @override
  String get envelopes_noEnvelopes =>
      'No monthly budgets yet. Set some on the Budget tab; each becomes an envelope.';

  @override
  String get envelopes_moveMoney => 'Move money';

  @override
  String get envelopes_move => 'Move';

  @override
  String get envelopes_from => 'From';

  @override
  String get envelopes_to => 'To';

  @override
  String get envelopes_sameEnvelope => 'Pick two different envelopes.';

  @override
  String envelopes_assigned(String amount) {
    return 'assigned $amount';
  }

  @override
  String envelopes_spent(String amount) {
    return 'spent $amount';
  }

  @override
  String envelopes_carried(String amount) {
    return 'carried $amount';
  }

  @override
  String envelopes_moved(String amount) {
    return 'moved $amount';
  }

  @override
  String get envelopes_settingsTile => 'Envelope budgeting';

  @override
  String get chart_breakdown => 'Where your money went';

  @override
  String get chart_trend => 'Monthly spending';

  @override
  String get chart_daily => 'Daily spending';

  @override
  String get chart_budgets => 'Budgets';

  @override
  String get chart_thisWeek => 'This week';

  @override
  String get chart_thisMonth => 'This month';

  @override
  String get chart_lastMonth => 'Last month';

  @override
  String get chart_lastSixMonths => 'Last 6 months';

  @override
  String get chart_thisYear => 'This year';

  @override
  String get chart_other => 'Other';

  @override
  String get wrapped_title => 'Year in review';

  @override
  String get wrapped_settingsTile => 'Year in review';

  @override
  String get wrapped_emptyTitle => 'Not enough to review yet';

  @override
  String wrapped_emptyHint(int count) {
    return 'Log at least $count expenses in a year to unlock your year in review.';
  }

  @override
  String get wrapped_hideAmounts => 'Hide amounts';

  @override
  String get wrapped_share => 'Share this card';

  @override
  String wrapped_shareText(int year) {
    final intl.NumberFormat yearNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String yearString = yearNumberFormat.format(year);

    return 'My $yearString in money, made with ExpenseFlow';
  }

  @override
  String wrapped_cardHeader(String year) {
    return 'MY $year IN MONEY';
  }

  @override
  String wrapped_totalHeading(String amount) {
    return 'You spent $amount';
  }

  @override
  String wrapped_transactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'across $count transactions',
      one: 'across 1 transaction',
    );
    return '$_temp0';
  }

  @override
  String wrapped_perDay(String amount) {
    return 'About $amount a day';
  }

  @override
  String wrapped_lessThanLastYear(int percent, String year) {
    return '$percent% less than $year. Nice!';
  }

  @override
  String wrapped_moreThanLastYear(int percent, String year) {
    return '$percent% more than $year';
  }

  @override
  String get wrapped_categoriesHeading => 'Your categories';

  @override
  String wrapped_topCategory(String category) {
    return '$category was your #1';
  }

  @override
  String wrapped_topMerchant(String merchant) {
    return 'Your favourite: $merchant';
  }

  @override
  String wrapped_merchantVisits(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visits',
      one: '1 visit',
    );
    return '$_temp0, $amount in total';
  }

  @override
  String get wrapped_biggestHeading => 'The big one';

  @override
  String get wrapped_biggest => 'Biggest single expense';

  @override
  String get wrapped_rhythmHeading => 'Your rhythm';

  @override
  String wrapped_busiestMonth(String month) {
    return '$month was your biggest month';
  }

  @override
  String wrapped_busiestWeekday(String weekday) {
    return 'You spend most on ${weekday}s';
  }

  @override
  String wrapped_topPayment(String method) {
    return 'Paid mostly with $method';
  }

  @override
  String wrapped_noSpendHeading(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count no-spend days',
      one: '1 no-spend day',
    );
    return '$_temp0';
  }

  @override
  String wrapped_longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Longest streak: $count days in a row',
      one: 'Longest streak: 1 day',
    );
    return '$_temp0';
  }

  @override
  String get wrapped_outro => 'Here\'s to an even better year. 🥂';

  @override
  String get receipt_button => 'Scan a receipt';

  @override
  String get receipt_title => 'Scan a receipt';

  @override
  String get receipt_privacy =>
      'Read on your phone. The photo is never uploaded.';

  @override
  String get receipt_camera => 'Take a photo';

  @override
  String get receipt_gallery => 'Choose from gallery';

  @override
  String get receipt_reading => 'Reading the receipt…';

  @override
  String get receipt_unreadable =>
      'Couldn\'t read that receipt. Try a flat, well-lit photo of the whole bill.';

  @override
  String get receipt_reviewTitle => 'Check what we read';

  @override
  String get receipt_total => 'Total';

  @override
  String get receipt_merchant => 'Merchant';

  @override
  String get receipt_date => 'Date';

  @override
  String get receipt_gst => 'GST';

  @override
  String get receipt_notFound => 'Not found';

  @override
  String receipt_items(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get receipt_itemsHint =>
      'Untick items that weren\'t yours (e.g. a shared bill).';

  @override
  String get receipt_use => 'Fill in the expense';

  @override
  String receipt_dateChip(String date) {
    return 'Dated $date (from receipt)';
  }

  @override
  String get groups_settingsTile => 'Shared budgets & splits';

  @override
  String get groups_title => 'Shared budgets';

  @override
  String get groups_new => 'New group';

  @override
  String get groups_create => 'Create group';

  @override
  String get groups_join => 'Join with a code';

  @override
  String get groups_joinButton => 'Join';

  @override
  String get groups_joinHint => 'Ask a member for the 6-character invite code.';

  @override
  String get groups_emptyTitle => 'Share a budget';

  @override
  String get groups_emptyHint =>
      'Track household or roommate spending together and split bills fairly.';

  @override
  String get groups_signInNeeded => 'Sign in to use shared budgets';

  @override
  String get groups_signInHint =>
      'Groups sync between members, so they need an account. Your personal expenses stay on this device.';

  @override
  String get groups_kindHousehold => 'Household';

  @override
  String get groups_kindRoommates => 'Roommates';

  @override
  String get groups_kindTrip => 'Trip';

  @override
  String get groups_kindOther => 'Other';

  @override
  String get groups_nameHint => 'Group name, e.g. Flat 302';

  @override
  String groups_budgetHint(String symbol) {
    return 'Monthly budget ($symbol), optional';
  }

  @override
  String groups_budgetPerMonth(String amount) {
    return '$amount/month';
  }

  @override
  String groups_memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get groups_errorName => 'Give the group a name';

  @override
  String get groups_inviteNotFound => 'That invite code doesn\'t exist';

  @override
  String get groups_inviteExpired =>
      'That invite has expired. Ask for a new code.';

  @override
  String get groups_full =>
      'Couldn\'t join. The group may be full (20 members).';

  @override
  String get groups_network =>
      'Couldn\'t reach the server. Check your connection.';

  @override
  String get groups_invite => 'Invite members';

  @override
  String get groups_inviteHint =>
      'Valid for 7 days. Making a new code cancels the old one.';

  @override
  String get groups_copy => 'Copy';

  @override
  String get groups_share => 'Share';

  @override
  String groups_shareText(String group, String code) {
    return 'Join \"$group\" on ExpenseFlow: Settings → Shared budgets → Join with a code → $code';
  }

  @override
  String get groups_editBudget => 'Monthly budget';

  @override
  String get groups_leave => 'Leave group';

  @override
  String get groups_leaveConfirm =>
      'You\'ll lose access to this group\'s expenses. If you\'re the last member, the group is deleted.';

  @override
  String get groups_leaveUnsettled => 'Settle up before leaving.';

  @override
  String get groups_leaveOwner => 'You created this group, so you leave last.';

  @override
  String get groups_thisMonth => 'Spent together this month';

  @override
  String groups_left(String amount) {
    return '$amount left';
  }

  @override
  String groups_overBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get groups_balances => 'Balances';

  @override
  String get groups_settled => 'Settled';

  @override
  String groups_isOwed(String amount) {
    return 'gets $amount';
  }

  @override
  String groups_owes(String amount) {
    return 'owes $amount';
  }

  @override
  String get groups_settleUp => 'Settle up';

  @override
  String groups_pays(String from, String to, String amount) {
    return '$from pays $to $amount';
  }

  @override
  String get groups_record => 'Mark paid';

  @override
  String get groups_paymentRecorded => 'Payment recorded';

  @override
  String get groups_payments => 'Payments';

  @override
  String groups_paid(String from, String to, String amount) {
    return '$from paid $to $amount';
  }

  @override
  String get groups_expenses => 'Expenses';

  @override
  String get groups_noExpenses => 'No shared expenses yet.';

  @override
  String get groups_addExpense => 'Add expense';

  @override
  String get groups_expenseHint => 'What was it? e.g. Groceries';

  @override
  String groups_amountHint(String symbol) {
    return 'Amount ($symbol)';
  }

  @override
  String get groups_paidBy => 'Paid by';

  @override
  String groups_paidByName(String name) {
    return '$name paid';
  }

  @override
  String get groups_split => 'Split';

  @override
  String get groups_splitEqual => 'Equally';

  @override
  String get groups_splitCustom => 'Custom amounts';

  @override
  String get groups_category => 'Category';

  @override
  String get groups_addMine => 'Add my share to my expenses';

  @override
  String get groups_addMineHint => 'Keeps your personal budgets accurate.';

  @override
  String get groups_errorTitle => 'Add a description';

  @override
  String get groups_errorPayer => 'Pick who paid';

  @override
  String get groups_errorShares => 'Shares must add up to the amount';

  @override
  String get groups_you => 'You';

  @override
  String groups_yourShare(String amount) {
    return 'your share $amount';
  }
}
