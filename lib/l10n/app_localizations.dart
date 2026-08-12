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
