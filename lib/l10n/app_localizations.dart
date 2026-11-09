import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'ExpenseFlow'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Track. Budget. Breathe.'**
  String get appTagline;

  /// No description provided for @onboarding_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboarding_skip;

  /// No description provided for @onboarding_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboarding_next;

  /// No description provided for @onboarding_getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboarding_getStarted;

  /// No description provided for @onboarding_slide1Title.
  ///
  /// In en, this message translates to:
  /// **'Track every expense'**
  String get onboarding_slide1Title;

  /// No description provided for @onboarding_slide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Log any expense in seconds with smart categories and handy notes.'**
  String get onboarding_slide1Subtitle;

  /// No description provided for @onboarding_slide2Title.
  ///
  /// In en, this message translates to:
  /// **'Budgets that keep you on track'**
  String get onboarding_slide2Title;

  /// No description provided for @onboarding_slide2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set monthly limits and see exactly where your money goes.'**
  String get onboarding_slide2Subtitle;

  /// No description provided for @onboarding_slide3Title.
  ///
  /// In en, this message translates to:
  /// **'Insights that help you breathe easy'**
  String get onboarding_slide3Title;

  /// No description provided for @onboarding_slide3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Understand your spending with clear insights and smart goals.'**
  String get onboarding_slide3Subtitle;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get common_google;

  /// No description provided for @common_apple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get common_apple;

  /// No description provided for @common_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get common_language;

  /// No description provided for @common_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get common_settings;

  /// No description provided for @common_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get common_loading;

  /// No description provided for @common_somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get common_somethingWentWrong;

  /// No description provided for @auth_createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get auth_createAccount;

  /// No description provided for @auth_signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your expenses in seconds'**
  String get auth_signupSubtitle;

  /// No description provided for @auth_fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get auth_fullName;

  /// No description provided for @auth_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get auth_nameRequired;

  /// No description provided for @auth_emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get auth_emailAddress;

  /// No description provided for @auth_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get auth_emailRequired;

  /// No description provided for @auth_invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get auth_invalidEmail;

  /// No description provided for @auth_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_password;

  /// No description provided for @auth_passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get auth_passwordRequired;

  /// No description provided for @auth_passwordMinChars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get auth_passwordMinChars;

  /// No description provided for @auth_passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get auth_passwordsDoNotMatch;

  /// No description provided for @auth_confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get auth_confirmPassword;

  /// No description provided for @auth_confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get auth_confirmPasswordRequired;

  /// No description provided for @auth_orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get auth_orContinueWith;

  /// No description provided for @auth_alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get auth_alreadyHaveAccount;

  /// No description provided for @auth_logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get auth_logIn;

  /// No description provided for @auth_welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get auth_welcomeBack;

  /// No description provided for @auth_loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to keep tracking your spending'**
  String get auth_loginSubtitle;

  /// No description provided for @auth_forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get auth_forgotPassword;

  /// No description provided for @auth_forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get auth_forgotPasswordTitle;

  /// No description provided for @auth_forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a link to reset your password'**
  String get auth_forgotPasswordSubtitle;

  /// No description provided for @auth_sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get auth_sendResetLink;

  /// No description provided for @auth_passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get auth_passwordResetSent;

  /// No description provided for @auth_dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get auth_dontHaveAccount;

  /// No description provided for @auth_signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get auth_signUp;

  /// No description provided for @auth_logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get auth_logOut;

  /// No description provided for @auth_logOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get auth_logOutQuestion;

  /// No description provided for @auth_logOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to access your data.'**
  String get auth_logOutSubtitle;

  /// No description provided for @auth_profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get auth_profileUpdated;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settings_darkMode;

  /// No description provided for @settings_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications;

  /// No description provided for @settings_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settings_currency;

  /// No description provided for @settings_exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settings_exportData;

  /// No description provided for @settings_editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get settings_editName;

  /// No description provided for @settings_editNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This name is shown on your profile and saved to your account'**
  String get settings_editNameSubtitle;

  /// No description provided for @settings_yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settings_yourName;

  /// No description provided for @settings_nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get settings_nameCannotBeEmpty;

  /// No description provided for @settings_changeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Change Currency'**
  String get settings_changeCurrency;

  /// No description provided for @settings_chooseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred currency'**
  String get settings_chooseCurrency;

  /// No description provided for @settings_logReport.
  ///
  /// In en, this message translates to:
  /// **'Log report'**
  String get settings_logReport;

  /// No description provided for @settings_logReportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating log report…'**
  String get settings_logReportGenerating;

  /// No description provided for @settings_logReportReady.
  ///
  /// In en, this message translates to:
  /// **'Log report ready'**
  String get settings_logReportReady;

  /// No description provided for @settings_logReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create log report'**
  String get settings_logReportFailed;

  /// No description provided for @language_title.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get language_title;

  /// No description provided for @language_choose.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get language_choose;

  /// No description provided for @dashboard_goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get dashboard_goodMorning;

  /// No description provided for @dashboard_goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get dashboard_goodAfternoon;

  /// No description provided for @dashboard_goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get dashboard_goodEvening;

  /// No description provided for @dashboard_goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get dashboard_goodNight;

  /// No description provided for @dashboard_totalSpentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Total spent this month'**
  String get dashboard_totalSpentThisMonth;

  /// No description provided for @dashboard_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get dashboard_categories;

  /// No description provided for @dashboard_recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get dashboard_recent;

  /// No description provided for @dashboard_noTransactionsToday.
  ///
  /// In en, this message translates to:
  /// **'No transactions today'**
  String get dashboard_noTransactionsToday;

  /// No description provided for @dashboard_spendingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Spending breakdown'**
  String get dashboard_spendingBreakdown;

  /// No description provided for @dashboard_monthlyTrend.
  ///
  /// In en, this message translates to:
  /// **'Monthly trend'**
  String get dashboard_monthlyTrend;

  /// No description provided for @addExpense_title.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense_title;

  /// No description provided for @addExpense_validAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get addExpense_validAmount;

  /// No description provided for @addExpense_selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get addExpense_selectCategory;

  /// No description provided for @addExpense_titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get addExpense_titleRequired;

  /// No description provided for @addExpense_selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get addExpense_selectPaymentMethod;

  /// No description provided for @addExpense_added.
  ///
  /// In en, this message translates to:
  /// **'Expense added successfully'**
  String get addExpense_added;

  /// No description provided for @addExpense_titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title*'**
  String get addExpense_titleLabel;

  /// No description provided for @addExpense_expenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense title'**
  String get addExpense_expenseTitle;

  /// No description provided for @addExpense_categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category*'**
  String get addExpense_categoryLabel;

  /// No description provided for @addExpense_paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method*'**
  String get addExpense_paymentMethodLabel;

  /// No description provided for @addExpense_note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get addExpense_note;

  /// No description provided for @addExpense_noteHint.
  ///
  /// In en, this message translates to:
  /// **'Add Note (Optional)'**
  String get addExpense_noteHint;

  /// No description provided for @editExpense_title.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editExpense_title;

  /// No description provided for @editExpense_updated.
  ///
  /// In en, this message translates to:
  /// **'Expense updated successfully'**
  String get editExpense_updated;

  /// No description provided for @editExpense_deleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted successfully'**
  String get editExpense_deleted;

  /// No description provided for @detail_transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get detail_transactionDetails;

  /// No description provided for @detail_deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get detail_deleteTransaction;

  /// No description provided for @detail_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get detail_deleteConfirm;

  /// No description provided for @detail_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get detail_date;

  /// No description provided for @detail_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get detail_category;

  /// No description provided for @detail_paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get detail_paymentMethod;

  /// No description provided for @detail_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get detail_currency;

  /// No description provided for @detail_noNote.
  ///
  /// In en, this message translates to:
  /// **'No note added.'**
  String get detail_noNote;

  /// No description provided for @budget_title.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget_title;

  /// No description provided for @budget_totalSpentThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Total spent this month'**
  String get budget_totalSpentThisMonth;

  /// No description provided for @budget_noExpensesYet.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get budget_noExpensesYet;

  /// No description provided for @budget_setFirstBudget.
  ///
  /// In en, this message translates to:
  /// **'Set your first budget'**
  String get budget_setFirstBudget;

  /// No description provided for @budget_setFirstBudgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give each category a monthly limit so you can see where your money is going and stay on track.'**
  String get budget_setFirstBudgetSubtitle;

  /// No description provided for @budget_createYourBudget.
  ///
  /// In en, this message translates to:
  /// **'Create your budget'**
  String get budget_createYourBudget;

  /// No description provided for @budget_skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get budget_skipForNow;

  /// No description provided for @budget_notifiedBeforeOverspend.
  ///
  /// In en, this message translates to:
  /// **'Get notified before you overspend'**
  String get budget_notifiedBeforeOverspend;

  /// No description provided for @budget_spendingTrends.
  ///
  /// In en, this message translates to:
  /// **'See spending trends by category'**
  String get budget_spendingTrends;

  /// No description provided for @budget_editBudgets.
  ///
  /// In en, this message translates to:
  /// **'Edit budgets'**
  String get budget_editBudgets;

  /// No description provided for @budget_createBudget.
  ///
  /// In en, this message translates to:
  /// **'Create budget'**
  String get budget_createBudget;

  /// No description provided for @budget_createHint.
  ///
  /// In en, this message translates to:
  /// **'Set a monthly limit for each category. You can change these anytime.'**
  String get budget_createHint;

  /// No description provided for @budget_totalMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Total monthly budget'**
  String get budget_totalMonthlyBudget;

  /// No description provided for @budget_periodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budget_periodMonthly;

  /// No description provided for @budget_periodQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get budget_periodQuarterly;

  /// No description provided for @budget_periodYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budget_periodYearly;

  /// No description provided for @budget_periodNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get budget_periodNoLimit;

  /// Shows percentage of budget used
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String budget_percentUsed(String percent);

  /// No description provided for @budget_spendingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Spending breakdown'**
  String get budget_spendingBreakdown;

  /// No description provided for @budget_others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get budget_others;

  /// How much was spent in a period, e.g. ₹1,200 spent
  ///
  /// In en, this message translates to:
  /// **'{amount} spent'**
  String budget_spentAmount(String amount);

  /// Shown before a budget limit, e.g. of ₹5,000
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String budget_ofAmount(String amount);

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notifications_allCaughtUp;

  /// No description provided for @notifications_none.
  ///
  /// In en, this message translates to:
  /// **'You have no new notifications.'**
  String get notifications_none;

  /// No description provided for @notifications_budgetLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Budget limit reached'**
  String get notifications_budgetLimitReached;

  /// No description provided for @notifications_budgetLimitMsg.
  ///
  /// In en, this message translates to:
  /// **'You have used 80% of your Shopping budget this month.'**
  String get notifications_budgetLimitMsg;

  /// No description provided for @notifications_dataSynced.
  ///
  /// In en, this message translates to:
  /// **'Data synced'**
  String get notifications_dataSynced;

  /// No description provided for @notifications_dataSyncedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your expenses were successfully synced to the cloud.'**
  String get notifications_dataSyncedMsg;

  /// No description provided for @notifications_spendingInsight.
  ///
  /// In en, this message translates to:
  /// **'Spending insight'**
  String get notifications_spendingInsight;

  /// No description provided for @notifications_spendingInsightMsg.
  ///
  /// In en, this message translates to:
  /// **'Your entertainment spending is 15% lower than last month.'**
  String get notifications_spendingInsightMsg;

  /// No description provided for @notifications_twoHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'2h ago'**
  String get notifications_twoHoursAgo;

  /// No description provided for @notifications_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notifications_yesterday;

  /// No description provided for @notifications_twoDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'2 days ago'**
  String get notifications_twoDaysAgo;

  /// No description provided for @category_food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get category_food;

  /// No description provided for @category_bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get category_bills;

  /// No description provided for @category_shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get category_shopping;

  /// No description provided for @category_transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get category_transport;

  /// No description provided for @category_entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get category_entertainment;

  /// No description provided for @category_health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get category_health;

  /// No description provided for @category_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get category_travel;

  /// No description provided for @category_education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get category_education;

  /// No description provided for @category_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get category_other;

  /// No description provided for @payment_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payment_cash;

  /// No description provided for @payment_card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payment_card;

  /// No description provided for @payment_upi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get payment_upi;

  /// No description provided for @payment_bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get payment_bankTransfer;

  /// No description provided for @payment_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get payment_other;

  /// Shown when a change was saved locally but cloud sync failed
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Not synced: {message}'**
  String sync_savedLocalNotSynced(String message);

  /// Shown when load succeeded from local storage but remote refresh failed
  ///
  /// In en, this message translates to:
  /// **'Showing saved data. Refresh failed: {message}'**
  String sync_showingSavedData(String message);

  /// Shown when the realtime remote sync stream errors
  ///
  /// In en, this message translates to:
  /// **'Live sync failed: {message}'**
  String sync_liveSyncFailed(String message);

  /// No description provided for @sync_ratesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live exchange rates are unavailable. Amounts are shown in INR.'**
  String get sync_ratesUnavailable;

  /// No description provided for @error_default.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get error_default;

  /// No description provided for @error_noConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection.'**
  String get error_noConnection;

  /// No description provided for @error_timeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Please try again.'**
  String get error_timeout;

  /// No description provided for @error_invalidData.
  ///
  /// In en, this message translates to:
  /// **'The data received was invalid. Please try again.'**
  String get error_invalidData;

  /// Server returned an error status code
  ///
  /// In en, this message translates to:
  /// **'Server error ({status}). Please try again later.'**
  String error_serverError(String status);

  /// No description provided for @transaction_searchHint.
  ///
  /// In en, this message translates to:
  /// **'🔍 Search Transactions'**
  String get transaction_searchHint;

  /// No description provided for @transaction_newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get transaction_newest;

  /// No description provided for @transaction_oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get transaction_oldest;

  /// No description provided for @transaction_highestAmount.
  ///
  /// In en, this message translates to:
  /// **'Highest Amount'**
  String get transaction_highestAmount;

  /// No description provided for @transaction_lowestAmount.
  ///
  /// In en, this message translates to:
  /// **'Lowest Amount'**
  String get transaction_lowestAmount;

  /// No description provided for @transaction_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get transaction_today;

  /// No description provided for @transaction_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get transaction_yesterday;

  /// No description provided for @addExpense_merchantLabel.
  ///
  /// In en, this message translates to:
  /// **'Merchant (optional)'**
  String get addExpense_merchantLabel;

  /// No description provided for @addExpense_merchantHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Swiggy, Amazon, D-Mart'**
  String get addExpense_merchantHint;

  /// No description provided for @addExpense_repeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get addExpense_repeatLabel;

  /// No description provided for @recurrence_none.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get recurrence_none;

  /// No description provided for @recurrence_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrence_daily;

  /// No description provided for @recurrence_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrence_weekly;

  /// No description provided for @recurrence_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrence_monthly;

  /// No description provided for @recurrence_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrence_yearly;

  /// No description provided for @detail_merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get detail_merchant;

  /// No description provided for @detail_paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid amount'**
  String get detail_paidAmount;

  /// No description provided for @detail_recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get detail_recurring;

  /// No description provided for @recurring_title.
  ///
  /// In en, this message translates to:
  /// **'Recurring expenses'**
  String get recurring_title;

  /// No description provided for @recurring_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recurring expenses'**
  String get recurring_emptyTitle;

  /// No description provided for @recurring_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a Repeat option when adding an expense to log rent, EMIs or subscriptions automatically.'**
  String get recurring_emptyHint;

  /// Next due date of a recurring expense
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String recurring_nextDue(String date);

  /// No description provided for @recurring_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurring_paused;

  /// No description provided for @recurring_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recurring expense?'**
  String get recurring_deleteTitle;

  /// No description provided for @recurring_deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'No new entries will be created. Expenses already logged are kept.'**
  String get recurring_deleteMessage;

  /// No description provided for @settings_recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring expenses'**
  String get settings_recurring;

  /// No description provided for @settings_appLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settings_appLock;

  /// No description provided for @appLock_lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'ExpenseFlow is locked'**
  String get appLock_lockedTitle;

  /// No description provided for @appLock_lockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock to see your expenses'**
  String get appLock_lockedSubtitle;

  /// No description provided for @appLock_unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get appLock_unlock;

  /// No description provided for @appLock_reason.
  ///
  /// In en, this message translates to:
  /// **'Unlock ExpenseFlow'**
  String get appLock_reason;

  /// No description provided for @appLock_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify it\'s you. Try again.'**
  String get appLock_failed;

  /// No description provided for @appLock_lockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a little while.'**
  String get appLock_lockedOut;

  /// No description provided for @appLock_enableReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm to turn on app lock'**
  String get appLock_enableReason;

  /// No description provided for @appLock_disableReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm to turn off app lock'**
  String get appLock_disableReason;

  /// No description provided for @appLock_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Set up a screen lock or fingerprint on your device first.'**
  String get appLock_unavailable;

  /// No description provided for @addExpense_categorySuggested.
  ///
  /// In en, this message translates to:
  /// **'✨ Suggested'**
  String get addExpense_categorySuggested;

  /// No description provided for @budget_paceAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At this pace, runs out around {date}'**
  String budget_paceAtRisk(String date);

  /// No description provided for @budget_paceExceeded.
  ///
  /// In en, this message translates to:
  /// **'Over budget by {amount}'**
  String budget_paceExceeded(String amount);

  /// No description provided for @budget_paceOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track · {amount}/day for {days} days'**
  String budget_paceOnTrack(String amount, int days);

  /// No description provided for @capture_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get capture_add;

  /// No description provided for @capture_banner.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment found in your SMS} other{{count} payments found in your SMS}}'**
  String capture_banner(int count);

  /// No description provided for @capture_defaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get capture_defaultTitle;

  /// No description provided for @capture_dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get capture_dismiss;

  /// No description provided for @capture_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'New bank and UPI payments will show up here for you to confirm.'**
  String get capture_emptyHint;

  /// No description provided for @capture_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get capture_emptyTitle;

  /// No description provided for @capture_possibleDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You may have already logged this'**
  String get capture_possibleDuplicate;

  /// No description provided for @capture_review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get capture_review;

  /// No description provided for @capture_showSms.
  ///
  /// In en, this message translates to:
  /// **'Show SMS'**
  String get capture_showSms;

  /// No description provided for @capture_title.
  ///
  /// In en, this message translates to:
  /// **'Detected payments'**
  String get capture_title;

  /// No description provided for @capture_tooLarge.
  ///
  /// In en, this message translates to:
  /// **'This amount is above the per-expense limit. Add it manually.'**
  String get capture_tooLarge;

  /// No description provided for @capture_unknownMerchant.
  ///
  /// In en, this message translates to:
  /// **'Unknown payee'**
  String get capture_unknownMerchant;

  /// No description provided for @categories_add.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categories_add;

  /// No description provided for @categories_archiveMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be hidden from pickers. Expenses already in it keep their category.'**
  String get categories_archiveMessage;

  /// No description provided for @categories_archiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String categories_archiveTitle(String name);

  /// No description provided for @categories_builtIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get categories_builtIn;

  /// No description provided for @categories_colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get categories_colorLabel;

  /// No description provided for @categories_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categories_editTitle;

  /// No description provided for @categories_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add your own, like Rent, Kirana or Maid.'**
  String get categories_emptyHint;

  /// No description provided for @categories_errorDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists'**
  String get categories_errorDuplicate;

  /// No description provided for @categories_errorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get categories_errorEmpty;

  /// No description provided for @categories_errorTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long'**
  String get categories_errorTooLong;

  /// No description provided for @categories_errorTooMany.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the category limit'**
  String get categories_errorTooMany;

  /// No description provided for @categories_iconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categories_iconLabel;

  /// No description provided for @categories_nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rent, Kirana, Pet care'**
  String get categories_nameHint;

  /// No description provided for @categories_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categories_nameLabel;

  /// No description provided for @categories_newTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categories_newTitle;

  /// No description provided for @categories_title.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories_title;

  /// No description provided for @categories_yours.
  ///
  /// In en, this message translates to:
  /// **'Your categories'**
  String get categories_yours;

  /// No description provided for @goals_addMoney.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get goals_addMoney;

  /// No description provided for @goals_amountHint.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get goals_amountHint;

  /// No description provided for @goals_by.
  ///
  /// In en, this message translates to:
  /// **'By {date}'**
  String goals_by(String date);

  /// No description provided for @goals_complete.
  ///
  /// In en, this message translates to:
  /// **'Goal reached 🎉'**
  String get goals_complete;

  /// No description provided for @goals_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get goals_delete;

  /// No description provided for @goals_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Save towards a trip, a phone or an emergency fund and see how much to set aside each day.'**
  String get goals_emptyHint;

  /// No description provided for @goals_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet'**
  String get goals_emptyTitle;

  /// No description provided for @goals_initialLabel.
  ///
  /// In en, this message translates to:
  /// **'Already saved (optional)'**
  String get goals_initialLabel;

  /// No description provided for @goals_nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Goa trip'**
  String get goals_nameHint;

  /// No description provided for @goals_new.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goals_new;

  /// No description provided for @goals_overdue.
  ///
  /// In en, this message translates to:
  /// **'Target date has passed'**
  String get goals_overdue;

  /// No description provided for @goals_perDay.
  ///
  /// In en, this message translates to:
  /// **'Save {amount}/day · {days} days left'**
  String goals_perDay(String amount, int days);

  /// No description provided for @goals_pickDate.
  ///
  /// In en, this message translates to:
  /// **'Set a target date (optional)'**
  String get goals_pickDate;

  /// No description provided for @goals_remaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String goals_remaining(String amount);

  /// No description provided for @goals_savedOf.
  ///
  /// In en, this message translates to:
  /// **'{saved} of {target}'**
  String goals_savedOf(String saved, String target);

  /// No description provided for @goals_targetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target ({symbol})'**
  String goals_targetLabel(String symbol);

  /// No description provided for @goals_title.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get goals_title;

  /// No description provided for @goals_withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get goals_withdraw;

  /// No description provided for @safeToSpend_afterBills.
  ///
  /// In en, this message translates to:
  /// **'After setting aside {amount} for upcoming bills'**
  String safeToSpend_afterBills(String amount);

  /// No description provided for @safeToSpend_basedOnBudgets.
  ///
  /// In en, this message translates to:
  /// **'Based on what\'s left in your budgets'**
  String get safeToSpend_basedOnBudgets;

  /// No description provided for @safeToSpend_overBudget.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 budget is over its limit} other{{count} budgets are over their limit}}'**
  String safeToSpend_overBudget(int count);

  /// No description provided for @safeToSpend_setBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'Set a budget to see how much you can safely spend each day'**
  String get safeToSpend_setBudgetHint;

  /// No description provided for @safeToSpend_title.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend today'**
  String get safeToSpend_title;

  /// No description provided for @settings_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settings_categories;

  /// No description provided for @settings_goals.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get settings_goals;

  /// No description provided for @settings_smsCapture.
  ///
  /// In en, this message translates to:
  /// **'Detect payments from SMS'**
  String get settings_smsCapture;

  /// No description provided for @settings_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get settings_subscriptions;

  /// No description provided for @sms_disclosureAccept.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get sms_disclosureAccept;

  /// No description provided for @sms_disclosureBody.
  ///
  /// In en, this message translates to:
  /// **'ExpenseFlow reads bank and UPI SMS on this phone to find your payments. Messages are processed only on your device and are never uploaded or shared. You review every payment before it is saved. You can turn this off any time in Settings.'**
  String get sms_disclosureBody;

  /// No description provided for @sms_disclosureDecline.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get sms_disclosureDecline;

  /// No description provided for @sms_disclosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Detect payments from SMS?'**
  String get sms_disclosureTitle;

  /// No description provided for @sms_permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'SMS permission is needed. You can allow it in system settings.'**
  String get sms_permissionDenied;

  /// No description provided for @subscriptions_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'When a merchant charges you a similar amount every week, month or year, it shows up here.'**
  String get subscriptions_emptyHint;

  /// No description provided for @subscriptions_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions found yet'**
  String get subscriptions_emptyTitle;

  /// No description provided for @subscriptions_monthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'You spend about this much per month on subscriptions'**
  String get subscriptions_monthlyTotal;

  /// No description provided for @subscriptions_nextCharge.
  ///
  /// In en, this message translates to:
  /// **'Next charge {date} · {yearly}/year'**
  String subscriptions_nextCharge(String date, String yearly);

  /// No description provided for @subscriptions_title.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions_title;

  /// No description provided for @subscriptions_track.
  ///
  /// In en, this message translates to:
  /// **'Auto-log'**
  String get subscriptions_track;

  /// No description provided for @subscriptions_tracked.
  ///
  /// In en, this message translates to:
  /// **'Auto-logged'**
  String get subscriptions_tracked;

  /// No description provided for @subscriptions_trackedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will now be logged automatically'**
  String subscriptions_trackedMessage(String name);

  /// No description provided for @subscriptions_yearlyTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} per year'**
  String subscriptions_yearlyTotal(String amount);

  /// No description provided for @dashboard_paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get dashboard_paymentMethods;

  /// No description provided for @dashboard_spendCalendar.
  ///
  /// In en, this message translates to:
  /// **'Spending calendar'**
  String get dashboard_spendCalendar;

  /// No description provided for @insights_noSpendThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No spending logged this month yet.'**
  String get insights_noSpendThisMonth;

  /// No description provided for @insights_digitalShare.
  ///
  /// In en, this message translates to:
  /// **'{percent}% paid digitally this month'**
  String insights_digitalShare(String percent);

  /// No description provided for @insights_digitalUp.
  ///
  /// In en, this message translates to:
  /// **'▲ {points} pts vs last month'**
  String insights_digitalUp(String points);

  /// No description provided for @insights_digitalDown.
  ///
  /// In en, this message translates to:
  /// **'▼ {points} pts vs last month'**
  String insights_digitalDown(String points);

  /// No description provided for @streak_current.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No no-spend streak right now} =1{1-day no-spend streak} other{{count}-day no-spend streak}}'**
  String streak_current(int count);

  /// No description provided for @streak_monthSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 no-spend day} other{{count} no-spend days}} this month · best run {best}'**
  String streak_monthSummary(int count, int best);

  /// No description provided for @calendar_noSpend.
  ///
  /// In en, this message translates to:
  /// **'no spending'**
  String get calendar_noSpend;

  /// No description provided for @notif_billReminders.
  ///
  /// In en, this message translates to:
  /// **'Bill & EMI reminders'**
  String get notif_billReminders;

  /// No description provided for @tax_label.
  ///
  /// In en, this message translates to:
  /// **'Tax deduction'**
  String get tax_label;

  /// No description provided for @tax_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get tax_none;

  /// No description provided for @tax_desc80C.
  ///
  /// In en, this message translates to:
  /// **'LIC, PPF, ELSS, tuition fees, home-loan principal'**
  String get tax_desc80C;

  /// No description provided for @tax_desc80D.
  ///
  /// In en, this message translates to:
  /// **'Health insurance premiums and preventive check-ups'**
  String get tax_desc80D;

  /// No description provided for @tax_descHra.
  ///
  /// In en, this message translates to:
  /// **'House rent paid (exempt amount depends on salary and city)'**
  String get tax_descHra;

  /// No description provided for @tax_desc80G.
  ///
  /// In en, this message translates to:
  /// **'Donations to eligible charities'**
  String get tax_desc80G;

  /// No description provided for @tax_desc80E.
  ///
  /// In en, this message translates to:
  /// **'Interest on an education loan'**
  String get tax_desc80E;

  /// No description provided for @tax_summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax deductions'**
  String get tax_summaryTitle;

  /// No description provided for @settings_taxSummary.
  ///
  /// In en, this message translates to:
  /// **'Tax deductions'**
  String get settings_taxSummary;

  /// No description provided for @tax_totalClaimable.
  ///
  /// In en, this message translates to:
  /// **'Estimated deductible amount'**
  String get tax_totalClaimable;

  /// No description provided for @tax_oldRegimeNote.
  ///
  /// In en, this message translates to:
  /// **'Applies under the old tax regime. Guidance only, not tax advice.'**
  String get tax_oldRegimeNote;

  /// No description provided for @tax_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tax-tagged expenses'**
  String get tax_emptyTitle;

  /// No description provided for @tax_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tag rent, insurance, school fees or donations when you add them to see your yearly deduction summary here.'**
  String get tax_emptyHint;

  /// No description provided for @tax_capUsed.
  ///
  /// In en, this message translates to:
  /// **'{claimable} of {cap} limit used'**
  String tax_capUsed(String claimable, String cap);

  /// No description provided for @tax_capRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} more can still be claimed'**
  String tax_capRemaining(String amount);

  /// No description provided for @tax_noCap.
  ///
  /// In en, this message translates to:
  /// **'No fixed limit'**
  String get tax_noCap;

  /// No description provided for @tax_expenseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expense} other{{count} expenses}}'**
  String tax_expenseCount(int count);

  /// No description provided for @detail_taxTag.
  ///
  /// In en, this message translates to:
  /// **'Tax section'**
  String get detail_taxTag;

  /// No description provided for @export_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get export_share;

  /// No description provided for @rollover_title.
  ///
  /// In en, this message translates to:
  /// **'Unspent budget'**
  String get rollover_title;

  /// No description provided for @rollover_hint.
  ///
  /// In en, this message translates to:
  /// **'What happens to money left over when this budget period ends.'**
  String get rollover_hint;

  /// No description provided for @rollover_rowLabel.
  ///
  /// In en, this message translates to:
  /// **'Rollover'**
  String get rollover_rowLabel;

  /// No description provided for @rollover_off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get rollover_off;

  /// No description provided for @rollover_offHint.
  ///
  /// In en, this message translates to:
  /// **'Unspent money simply expires'**
  String get rollover_offHint;

  /// No description provided for @rollover_carryForward.
  ///
  /// In en, this message translates to:
  /// **'Carry forward'**
  String get rollover_carryForward;

  /// No description provided for @rollover_carryForwardHint.
  ///
  /// In en, this message translates to:
  /// **'Add last period\'s unspent amount to this period\'s limit'**
  String get rollover_carryForwardHint;

  /// No description provided for @rollover_toGoalShort.
  ///
  /// In en, this message translates to:
  /// **'To savings goal'**
  String get rollover_toGoalShort;

  /// No description provided for @rollover_toGoalNamed.
  ///
  /// In en, this message translates to:
  /// **'Save into {goal}'**
  String rollover_toGoalNamed(String goal);

  /// No description provided for @rollover_toGoalHint.
  ///
  /// In en, this message translates to:
  /// **'Unspent amount is added to this goal when each period ends'**
  String get rollover_toGoalHint;

  /// No description provided for @rollover_noGoals.
  ///
  /// In en, this message translates to:
  /// **'Create a savings goal to move unspent budget into it.'**
  String get rollover_noGoals;

  /// No description provided for @rollover_includes.
  ///
  /// In en, this message translates to:
  /// **'Includes {amount} rolled over'**
  String rollover_includes(String amount);

  /// No description provided for @settings_reports.
  ///
  /// In en, this message translates to:
  /// **'Statements & export'**
  String get settings_reports;

  /// No description provided for @reports_title.
  ///
  /// In en, this message translates to:
  /// **'Statements & export'**
  String get reports_title;

  /// No description provided for @reports_statementTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly statement'**
  String get reports_statementTitle;

  /// No description provided for @reports_statementHint.
  ///
  /// In en, this message translates to:
  /// **'A PDF with totals, category and payment-method breakdown, and every transaction.'**
  String get reports_statementHint;

  /// No description provided for @reports_noExpensesMonth.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month'**
  String get reports_noExpensesMonth;

  /// No description provided for @reports_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get reports_total;

  /// No description provided for @reports_transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reports_transactions;

  /// No description provided for @reports_topCategory.
  ///
  /// In en, this message translates to:
  /// **'Top category'**
  String get reports_topCategory;

  /// No description provided for @reports_sharePdf.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get reports_sharePdf;

  /// No description provided for @reports_csvTitle.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel (CSV)'**
  String get reports_csvTitle;

  /// No description provided for @reports_csvHint.
  ///
  /// In en, this message translates to:
  /// **'Opens in Excel, Google Sheets or Numbers.'**
  String get reports_csvHint;

  /// No description provided for @reports_rangeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get reports_rangeThisMonth;

  /// No description provided for @reports_rangeLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get reports_rangeLastMonth;

  /// No description provided for @reports_rangeFinancialYear.
  ///
  /// In en, this message translates to:
  /// **'This financial year'**
  String get reports_rangeFinancialYear;

  /// No description provided for @reports_rangeAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get reports_rangeAllTime;

  /// No description provided for @reports_exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get reports_exportCsv;

  /// No description provided for @reports_taxLink.
  ///
  /// In en, this message translates to:
  /// **'Tax deduction summary'**
  String get reports_taxLink;

  /// No description provided for @reports_privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Files are created on your phone. Nothing is uploaded unless you share it.'**
  String get reports_privacyNote;

  /// No description provided for @export_nothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export for this period'**
  String get export_nothing;

  /// No description provided for @export_failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the file. Please try again.'**
  String get export_failed;

  /// No description provided for @notif_captureAlerts.
  ///
  /// In en, this message translates to:
  /// **'Detected payments'**
  String get notif_captureAlerts;

  /// No description provided for @capture_loggedFromNotification.
  ///
  /// In en, this message translates to:
  /// **'Logged {amount} as {category}'**
  String capture_loggedFromNotification(String amount, String category);

  /// No description provided for @voice_title.
  ///
  /// In en, this message translates to:
  /// **'Speak your expense'**
  String get voice_title;

  /// No description provided for @voice_tapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic and speak'**
  String get voice_tapToSpeak;

  /// No description provided for @voice_listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get voice_listening;

  /// No description provided for @voice_examples.
  ///
  /// In en, this message translates to:
  /// **'Try “चहा 20 रुपये”, “petrol 500 cash” or “Swiggy 250 UPI”. Recognised on your phone.'**
  String get voice_examples;

  /// No description provided for @voice_onlineNote.
  ///
  /// In en, this message translates to:
  /// **'Online recognition: your voice is sent to the device\'s speech service (e.g. Google). Expense data stays on your phone.'**
  String get voice_onlineNote;

  /// No description provided for @voice_useOnline.
  ///
  /// In en, this message translates to:
  /// **'Use online recognition'**
  String get voice_useOnline;

  /// No description provided for @voice_permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed for voice entry. Enable it in Settings.'**
  String get voice_permissionDenied;

  /// No description provided for @voice_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition isn\'t available on this device.'**
  String get voice_unavailable;

  /// No description provided for @voice_offlineUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Offline speech for this language isn\'t installed. Download it in your phone\'s speech settings, or use online recognition.'**
  String get voice_offlineUnavailable;

  /// No description provided for @voice_needsInternet.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the speech service. Check your internet connection.'**
  String get voice_needsInternet;

  /// No description provided for @voice_noMatch.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that. Tap the mic and try again.'**
  String get voice_noMatch;

  /// No description provided for @voice_failed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get voice_failed;

  /// No description provided for @voice_filled.
  ///
  /// In en, this message translates to:
  /// **'Filled from “{transcript}”. Check and save.'**
  String voice_filled(String transcript);

  /// No description provided for @voice_button.
  ///
  /// In en, this message translates to:
  /// **'Add by voice'**
  String get voice_button;

  /// No description provided for @notif_loggingReminder.
  ///
  /// In en, this message translates to:
  /// **'Logging reminder'**
  String get notif_loggingReminder;

  /// No description provided for @notif_loggingLearned.
  ///
  /// In en, this message translates to:
  /// **'At your usual logging time, around {time}. Skipped on days you\'ve already logged.'**
  String notif_loggingLearned(String time);

  /// No description provided for @notif_loggingDefault.
  ///
  /// In en, this message translates to:
  /// **'At {time} for now. It moves to your usual logging time once ExpenseFlow learns it.'**
  String notif_loggingDefault(String time);

  /// No description provided for @events_title.
  ///
  /// In en, this message translates to:
  /// **'Events & trips'**
  String get events_title;

  /// No description provided for @events_settingsTile.
  ///
  /// In en, this message translates to:
  /// **'Events & trips'**
  String get events_settingsTile;

  /// No description provided for @events_new.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get events_new;

  /// No description provided for @events_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get events_edit;

  /// No description provided for @events_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get events_delete;

  /// No description provided for @events_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this event? Its expenses are kept and count towards your monthly budgets again.'**
  String get events_deleteConfirm;

  /// No description provided for @events_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get events_save;

  /// No description provided for @events_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan for big occasions'**
  String get events_emptyTitle;

  /// No description provided for @events_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Give Diwali, a wedding or a trip its own budget across categories. Trips can use their own currency.'**
  String get events_emptyHint;

  /// No description provided for @events_kindFestival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get events_kindFestival;

  /// No description provided for @events_kindWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get events_kindWedding;

  /// No description provided for @events_kindTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get events_kindTrip;

  /// No description provided for @events_kindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get events_kindOther;

  /// No description provided for @events_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Name, e.g. Diwali 2026'**
  String get events_nameHint;

  /// No description provided for @events_nameHintTrip.
  ///
  /// In en, this message translates to:
  /// **'Name, e.g. Bangkok trip'**
  String get events_nameHintTrip;

  /// No description provided for @events_budgetHint.
  ///
  /// In en, this message translates to:
  /// **'Budget ({symbol})'**
  String events_budgetHint(String symbol);

  /// No description provided for @events_days.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String events_days(int count);

  /// No description provided for @events_daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{last day} other{{count} days left}}'**
  String events_daysLeft(int count);

  /// No description provided for @events_starts.
  ///
  /// In en, this message translates to:
  /// **'starts {date}'**
  String events_starts(String date);

  /// No description provided for @events_ended.
  ///
  /// In en, this message translates to:
  /// **'ended {date}'**
  String events_ended(String date);

  /// No description provided for @events_tripCurrency.
  ///
  /// In en, this message translates to:
  /// **'Trip currency'**
  String get events_tripCurrency;

  /// No description provided for @events_tripCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'While the trip is on, new expenses are entered in this currency and converted at the live rate.'**
  String get events_tripCurrencyHint;

  /// No description provided for @events_categories.
  ///
  /// In en, this message translates to:
  /// **'Suggest for categories'**
  String get events_categories;

  /// No description provided for @events_allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get events_allCategories;

  /// No description provided for @events_separate.
  ///
  /// In en, this message translates to:
  /// **'Keep out of monthly budgets'**
  String get events_separate;

  /// No description provided for @events_separateHint.
  ///
  /// In en, this message translates to:
  /// **'This spending has its own budget here, so it won\'t use up your category budgets.'**
  String get events_separateHint;

  /// No description provided for @events_separateNote.
  ///
  /// In en, this message translates to:
  /// **'Kept out of your monthly category budgets.'**
  String get events_separateNote;

  /// No description provided for @events_spentOf.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {budget}'**
  String events_spentOf(String spent, String budget);

  /// No description provided for @events_perDayLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount}/day for {count, plural, =1{today} other{the next {count} days}}'**
  String events_perDayLeft(String amount, int count);

  /// No description provided for @events_over.
  ///
  /// In en, this message translates to:
  /// **'{amount} over budget'**
  String events_over(String amount);

  /// No description provided for @events_projectedOver.
  ///
  /// In en, this message translates to:
  /// **'At this pace you\'ll spend {amount}'**
  String events_projectedOver(String amount);

  /// No description provided for @events_byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get events_byCategory;

  /// No description provided for @events_transactions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String events_transactions(int count);

  /// No description provided for @events_noTransactions.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Expenses you add while this is on are tagged automatically.'**
  String get events_noTransactions;

  /// No description provided for @events_errorName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name (up to 40 characters).'**
  String get events_errorName;

  /// No description provided for @events_errorDates.
  ///
  /// In en, this message translates to:
  /// **'The end date must be on or after the start, within a year.'**
  String get events_errorDates;

  /// No description provided for @events_partOf.
  ///
  /// In en, this message translates to:
  /// **'Part of'**
  String get events_partOf;

  /// No description provided for @events_autoSelected.
  ///
  /// In en, this message translates to:
  /// **'auto-selected'**
  String get events_autoSelected;

  /// No description provided for @events_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get events_none;

  /// No description provided for @events_noRate.
  ///
  /// In en, this message translates to:
  /// **'No exchange rate for {code} yet. Connect to the internet once, or pick None to enter it in your usual currency.'**
  String events_noRate(String code);

  /// No description provided for @events_dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Happening now'**
  String get events_dashboardTitle;

  /// No description provided for @envelopes_title.
  ///
  /// In en, this message translates to:
  /// **'Envelope budgeting'**
  String get envelopes_title;

  /// No description provided for @envelopes_introTitle.
  ///
  /// In en, this message translates to:
  /// **'Give every rupee a job'**
  String get envelopes_introTitle;

  /// No description provided for @envelopes_intro1.
  ///
  /// In en, this message translates to:
  /// **'Tell ExpenseFlow how much you earn this month, then split all of it across your category budgets (envelopes) until nothing is left to assign.'**
  String get envelopes_intro1;

  /// No description provided for @envelopes_intro2.
  ///
  /// In en, this message translates to:
  /// **'What\'s left in an envelope carries into next month, and overspending does too.'**
  String get envelopes_intro2;

  /// No description provided for @envelopes_intro3.
  ///
  /// In en, this message translates to:
  /// **'Overspent? Move money from another envelope to cover it.'**
  String get envelopes_intro3;

  /// No description provided for @envelopes_introNote.
  ///
  /// In en, this message translates to:
  /// **'Uses your monthly category budgets. Weekly, quarterly and yearly budgets aren\'t envelopes. Replaces rollover settings while on.'**
  String get envelopes_introNote;

  /// No description provided for @envelopes_turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on envelope mode'**
  String get envelopes_turnOn;

  /// No description provided for @envelopes_turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off envelope mode'**
  String get envelopes_turnOff;

  /// No description provided for @envelopes_toBeAssigned.
  ///
  /// In en, this message translates to:
  /// **'To be assigned'**
  String get envelopes_toBeAssigned;

  /// No description provided for @envelopes_setIncomePrompt.
  ///
  /// In en, this message translates to:
  /// **'Set this month\'s income to start.'**
  String get envelopes_setIncomePrompt;

  /// No description provided for @envelopes_allAssigned.
  ///
  /// In en, this message translates to:
  /// **'Every rupee has a job. 🎉'**
  String get envelopes_allAssigned;

  /// No description provided for @envelopes_assignRest.
  ///
  /// In en, this message translates to:
  /// **'Assign {amount} more to your envelopes.'**
  String envelopes_assignRest(String amount);

  /// No description provided for @envelopes_overAssigned.
  ///
  /// In en, this message translates to:
  /// **'You\'ve assigned {amount} more than you earn. Lower some envelopes.'**
  String envelopes_overAssigned(String amount);

  /// No description provided for @envelopes_income.
  ///
  /// In en, this message translates to:
  /// **'Income this month: {amount}'**
  String envelopes_income(String amount);

  /// No description provided for @envelopes_noIncome.
  ///
  /// In en, this message translates to:
  /// **'No income set'**
  String get envelopes_noIncome;

  /// No description provided for @envelopes_setIncome.
  ///
  /// In en, this message translates to:
  /// **'Set income'**
  String get envelopes_setIncome;

  /// No description provided for @envelopes_incomeHint.
  ///
  /// In en, this message translates to:
  /// **'Money you\'ll have this month, e.g. salary. Used for future months until you change it.'**
  String get envelopes_incomeHint;

  /// No description provided for @envelopes_editAllocations.
  ///
  /// In en, this message translates to:
  /// **'Adjust envelope amounts'**
  String get envelopes_editAllocations;

  /// No description provided for @envelopes_overspentWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 envelope is overspent.} other{{count} envelopes are overspent.}} Tap it to move money in.'**
  String envelopes_overspentWarning(int count);

  /// No description provided for @envelopes_noEnvelopes.
  ///
  /// In en, this message translates to:
  /// **'No monthly budgets yet. Set some on the Budget tab; each becomes an envelope.'**
  String get envelopes_noEnvelopes;

  /// No description provided for @envelopes_moveMoney.
  ///
  /// In en, this message translates to:
  /// **'Move money'**
  String get envelopes_moveMoney;

  /// No description provided for @envelopes_move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get envelopes_move;

  /// No description provided for @envelopes_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get envelopes_from;

  /// No description provided for @envelopes_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get envelopes_to;

  /// No description provided for @envelopes_sameEnvelope.
  ///
  /// In en, this message translates to:
  /// **'Pick two different envelopes.'**
  String get envelopes_sameEnvelope;

  /// No description provided for @envelopes_assigned.
  ///
  /// In en, this message translates to:
  /// **'assigned {amount}'**
  String envelopes_assigned(String amount);

  /// No description provided for @envelopes_spent.
  ///
  /// In en, this message translates to:
  /// **'spent {amount}'**
  String envelopes_spent(String amount);

  /// No description provided for @envelopes_carried.
  ///
  /// In en, this message translates to:
  /// **'carried {amount}'**
  String envelopes_carried(String amount);

  /// No description provided for @envelopes_moved.
  ///
  /// In en, this message translates to:
  /// **'moved {amount}'**
  String envelopes_moved(String amount);

  /// No description provided for @envelopes_settingsTile.
  ///
  /// In en, this message translates to:
  /// **'Envelope budgeting'**
  String get envelopes_settingsTile;

  /// No description provided for @chart_breakdown.
  ///
  /// In en, this message translates to:
  /// **'Where your money went'**
  String get chart_breakdown;

  /// No description provided for @chart_trend.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending'**
  String get chart_trend;

  /// No description provided for @chart_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily spending'**
  String get chart_daily;

  /// No description provided for @chart_budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get chart_budgets;

  /// No description provided for @chart_thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get chart_thisWeek;

  /// No description provided for @chart_thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get chart_thisMonth;

  /// No description provided for @chart_lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get chart_lastMonth;

  /// No description provided for @chart_lastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get chart_lastSixMonths;

  /// No description provided for @chart_thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get chart_thisYear;

  /// No description provided for @chart_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chart_other;

  /// No description provided for @wrapped_title.
  ///
  /// In en, this message translates to:
  /// **'Year in review'**
  String get wrapped_title;

  /// No description provided for @wrapped_settingsTile.
  ///
  /// In en, this message translates to:
  /// **'Year in review'**
  String get wrapped_settingsTile;

  /// No description provided for @wrapped_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough to review yet'**
  String get wrapped_emptyTitle;

  /// No description provided for @wrapped_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Log at least {count} expenses in a year to unlock your year in review.'**
  String wrapped_emptyHint(int count);

  /// No description provided for @wrapped_hideAmounts.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get wrapped_hideAmounts;

  /// No description provided for @wrapped_share.
  ///
  /// In en, this message translates to:
  /// **'Share this card'**
  String get wrapped_share;

  /// No description provided for @wrapped_shareText.
  ///
  /// In en, this message translates to:
  /// **'My {year} in money, made with ExpenseFlow'**
  String wrapped_shareText(int year);

  /// No description provided for @wrapped_cardHeader.
  ///
  /// In en, this message translates to:
  /// **'MY {year} IN MONEY'**
  String wrapped_cardHeader(String year);

  /// No description provided for @wrapped_totalHeading.
  ///
  /// In en, this message translates to:
  /// **'You spent {amount}'**
  String wrapped_totalHeading(String amount);

  /// No description provided for @wrapped_transactions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{across 1 transaction} other{across {count} transactions}}'**
  String wrapped_transactions(int count);

  /// No description provided for @wrapped_perDay.
  ///
  /// In en, this message translates to:
  /// **'About {amount} a day'**
  String wrapped_perDay(String amount);

  /// No description provided for @wrapped_lessThanLastYear.
  ///
  /// In en, this message translates to:
  /// **'{percent}% less than {year}. Nice!'**
  String wrapped_lessThanLastYear(int percent, String year);

  /// No description provided for @wrapped_moreThanLastYear.
  ///
  /// In en, this message translates to:
  /// **'{percent}% more than {year}'**
  String wrapped_moreThanLastYear(int percent, String year);

  /// No description provided for @wrapped_categoriesHeading.
  ///
  /// In en, this message translates to:
  /// **'Your categories'**
  String get wrapped_categoriesHeading;

  /// No description provided for @wrapped_topCategory.
  ///
  /// In en, this message translates to:
  /// **'{category} was your #1'**
  String wrapped_topCategory(String category);

  /// No description provided for @wrapped_topMerchant.
  ///
  /// In en, this message translates to:
  /// **'Your favourite: {merchant}'**
  String wrapped_topMerchant(String merchant);

  /// No description provided for @wrapped_merchantVisits.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 visit} other{{count} visits}}, {amount} in total'**
  String wrapped_merchantVisits(int count, String amount);

  /// No description provided for @wrapped_biggestHeading.
  ///
  /// In en, this message translates to:
  /// **'The big one'**
  String get wrapped_biggestHeading;

  /// No description provided for @wrapped_biggest.
  ///
  /// In en, this message translates to:
  /// **'Biggest single expense'**
  String get wrapped_biggest;

  /// No description provided for @wrapped_rhythmHeading.
  ///
  /// In en, this message translates to:
  /// **'Your rhythm'**
  String get wrapped_rhythmHeading;

  /// No description provided for @wrapped_busiestMonth.
  ///
  /// In en, this message translates to:
  /// **'{month} was your biggest month'**
  String wrapped_busiestMonth(String month);

  /// No description provided for @wrapped_busiestWeekday.
  ///
  /// In en, this message translates to:
  /// **'You spend most on {weekday}s'**
  String wrapped_busiestWeekday(String weekday);

  /// No description provided for @wrapped_topPayment.
  ///
  /// In en, this message translates to:
  /// **'Paid mostly with {method}'**
  String wrapped_topPayment(String method);

  /// No description provided for @wrapped_noSpendHeading.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 no-spend day} other{{count} no-spend days}}'**
  String wrapped_noSpendHeading(int count);

  /// No description provided for @wrapped_longestStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Longest streak: 1 day} other{Longest streak: {count} days in a row}}'**
  String wrapped_longestStreak(int count);

  /// No description provided for @wrapped_outro.
  ///
  /// In en, this message translates to:
  /// **'Here\'s to an even better year. 🥂'**
  String get wrapped_outro;

  /// No description provided for @receipt_button.
  ///
  /// In en, this message translates to:
  /// **'Scan a receipt'**
  String get receipt_button;

  /// No description provided for @receipt_title.
  ///
  /// In en, this message translates to:
  /// **'Scan a receipt'**
  String get receipt_title;

  /// No description provided for @receipt_privacy.
  ///
  /// In en, this message translates to:
  /// **'Read on your phone. The photo is never uploaded.'**
  String get receipt_privacy;

  /// No description provided for @receipt_camera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get receipt_camera;

  /// No description provided for @receipt_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get receipt_gallery;

  /// No description provided for @receipt_reading.
  ///
  /// In en, this message translates to:
  /// **'Reading the receipt…'**
  String get receipt_reading;

  /// No description provided for @receipt_unreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that receipt. Try a flat, well-lit photo of the whole bill.'**
  String get receipt_unreadable;

  /// No description provided for @receipt_reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check what we read'**
  String get receipt_reviewTitle;

  /// No description provided for @receipt_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get receipt_total;

  /// No description provided for @receipt_merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get receipt_merchant;

  /// No description provided for @receipt_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get receipt_date;

  /// No description provided for @receipt_gst.
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get receipt_gst;

  /// No description provided for @receipt_notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get receipt_notFound;

  /// No description provided for @receipt_items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String receipt_items(int count);

  /// No description provided for @receipt_itemsHint.
  ///
  /// In en, this message translates to:
  /// **'Untick items that weren\'t yours (e.g. a shared bill).'**
  String get receipt_itemsHint;

  /// No description provided for @receipt_use.
  ///
  /// In en, this message translates to:
  /// **'Fill in the expense'**
  String get receipt_use;

  /// No description provided for @receipt_dateChip.
  ///
  /// In en, this message translates to:
  /// **'Dated {date} (from receipt)'**
  String receipt_dateChip(String date);

  /// No description provided for @groups_settingsTile.
  ///
  /// In en, this message translates to:
  /// **'Shared budgets & splits'**
  String get groups_settingsTile;

  /// No description provided for @groups_title.
  ///
  /// In en, this message translates to:
  /// **'Shared budgets'**
  String get groups_title;

  /// No description provided for @groups_new.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get groups_new;

  /// No description provided for @groups_create.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get groups_create;

  /// No description provided for @groups_join.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get groups_join;

  /// No description provided for @groups_joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get groups_joinButton;

  /// No description provided for @groups_joinHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a member for the 6-character invite code.'**
  String get groups_joinHint;

  /// No description provided for @groups_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Share a budget'**
  String get groups_emptyTitle;

  /// No description provided for @groups_emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Track household or roommate spending together and split bills fairly.'**
  String get groups_emptyHint;

  /// No description provided for @groups_signInNeeded.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use shared budgets'**
  String get groups_signInNeeded;

  /// No description provided for @groups_signInHint.
  ///
  /// In en, this message translates to:
  /// **'Groups sync between members, so they need an account. Your personal expenses stay on this device.'**
  String get groups_signInHint;

  /// No description provided for @groups_kindHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get groups_kindHousehold;

  /// No description provided for @groups_kindRoommates.
  ///
  /// In en, this message translates to:
  /// **'Roommates'**
  String get groups_kindRoommates;

  /// No description provided for @groups_kindTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get groups_kindTrip;

  /// No description provided for @groups_kindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get groups_kindOther;

  /// No description provided for @groups_nameHint.
  ///
  /// In en, this message translates to:
  /// **'Group name, e.g. Flat 302'**
  String get groups_nameHint;

  /// No description provided for @groups_budgetHint.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget ({symbol}), optional'**
  String groups_budgetHint(String symbol);

  /// No description provided for @groups_budgetPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount}/month'**
  String groups_budgetPerMonth(String amount);

  /// No description provided for @groups_memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String groups_memberCount(int count);

  /// No description provided for @groups_errorName.
  ///
  /// In en, this message translates to:
  /// **'Give the group a name'**
  String get groups_errorName;

  /// No description provided for @groups_inviteNotFound.
  ///
  /// In en, this message translates to:
  /// **'That invite code doesn\'t exist'**
  String get groups_inviteNotFound;

  /// No description provided for @groups_inviteExpired.
  ///
  /// In en, this message translates to:
  /// **'That invite has expired. Ask for a new code.'**
  String get groups_inviteExpired;

  /// No description provided for @groups_full.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t join. The group may be full (20 members).'**
  String get groups_full;

  /// No description provided for @groups_network.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection.'**
  String get groups_network;

  /// No description provided for @groups_invite.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get groups_invite;

  /// No description provided for @groups_inviteHint.
  ///
  /// In en, this message translates to:
  /// **'Valid for 7 days. Making a new code cancels the old one.'**
  String get groups_inviteHint;

  /// No description provided for @groups_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get groups_copy;

  /// No description provided for @groups_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get groups_share;

  /// No description provided for @groups_shareText.
  ///
  /// In en, this message translates to:
  /// **'Join \"{group}\" on ExpenseFlow: Settings → Shared budgets → Join with a code → {code}'**
  String groups_shareText(String group, String code);

  /// No description provided for @groups_editBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly budget'**
  String get groups_editBudget;

  /// No description provided for @groups_leave.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get groups_leave;

  /// No description provided for @groups_leaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'You\'ll lose access to this group\'s expenses. If you\'re the last member, the group is deleted.'**
  String get groups_leaveConfirm;

  /// No description provided for @groups_leaveUnsettled.
  ///
  /// In en, this message translates to:
  /// **'Settle up before leaving.'**
  String get groups_leaveUnsettled;

  /// No description provided for @groups_leaveOwner.
  ///
  /// In en, this message translates to:
  /// **'You created this group, so you leave last.'**
  String get groups_leaveOwner;

  /// No description provided for @groups_thisMonth.
  ///
  /// In en, this message translates to:
  /// **'Spent together this month'**
  String get groups_thisMonth;

  /// No description provided for @groups_left.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String groups_left(String amount);

  /// No description provided for @groups_overBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String groups_overBy(String amount);

  /// No description provided for @groups_balances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get groups_balances;

  /// No description provided for @groups_settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get groups_settled;

  /// No description provided for @groups_isOwed.
  ///
  /// In en, this message translates to:
  /// **'gets {amount}'**
  String groups_isOwed(String amount);

  /// No description provided for @groups_owes.
  ///
  /// In en, this message translates to:
  /// **'owes {amount}'**
  String groups_owes(String amount);

  /// No description provided for @groups_settleUp.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get groups_settleUp;

  /// No description provided for @groups_pays.
  ///
  /// In en, this message translates to:
  /// **'{from} pays {to} {amount}'**
  String groups_pays(String from, String to, String amount);

  /// No description provided for @groups_record.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get groups_record;

  /// No description provided for @groups_paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get groups_paymentRecorded;

  /// No description provided for @groups_payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get groups_payments;

  /// No description provided for @groups_paid.
  ///
  /// In en, this message translates to:
  /// **'{from} paid {to} {amount}'**
  String groups_paid(String from, String to, String amount);

  /// No description provided for @groups_expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get groups_expenses;

  /// No description provided for @groups_noExpenses.
  ///
  /// In en, this message translates to:
  /// **'No shared expenses yet.'**
  String get groups_noExpenses;

  /// No description provided for @groups_addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get groups_addExpense;

  /// No description provided for @groups_expenseHint.
  ///
  /// In en, this message translates to:
  /// **'What was it? e.g. Groceries'**
  String get groups_expenseHint;

  /// No description provided for @groups_amountHint.
  ///
  /// In en, this message translates to:
  /// **'Amount ({symbol})'**
  String groups_amountHint(String symbol);

  /// No description provided for @groups_paidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get groups_paidBy;

  /// No description provided for @groups_paidByName.
  ///
  /// In en, this message translates to:
  /// **'{name} paid'**
  String groups_paidByName(String name);

  /// No description provided for @groups_split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get groups_split;

  /// No description provided for @groups_splitEqual.
  ///
  /// In en, this message translates to:
  /// **'Equally'**
  String get groups_splitEqual;

  /// No description provided for @groups_splitCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom amounts'**
  String get groups_splitCustom;

  /// No description provided for @groups_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get groups_category;

  /// No description provided for @groups_addMine.
  ///
  /// In en, this message translates to:
  /// **'Add my share to my expenses'**
  String get groups_addMine;

  /// No description provided for @groups_addMineHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps your personal budgets accurate.'**
  String get groups_addMineHint;

  /// No description provided for @groups_errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get groups_errorTitle;

  /// No description provided for @groups_errorPayer.
  ///
  /// In en, this message translates to:
  /// **'Pick who paid'**
  String get groups_errorPayer;

  /// No description provided for @groups_errorShares.
  ///
  /// In en, this message translates to:
  /// **'Shares must add up to the amount'**
  String get groups_errorShares;

  /// No description provided for @groups_you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get groups_you;

  /// No description provided for @groups_yourShare.
  ///
  /// In en, this message translates to:
  /// **'your share {amount}'**
  String groups_yourShare(String amount);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
