import '../../../l10n/app_localizations.dart';
import '../domain/entities/recurring_expense_entity.dart';

extension RecurrenceFrequencyLabel on RecurrenceFrequency {
  String label(AppLocalizations l10n) {
    return switch (this) {
      RecurrenceFrequency.daily => l10n.recurrence_daily,
      RecurrenceFrequency.weekly => l10n.recurrence_weekly,
      RecurrenceFrequency.monthly => l10n.recurrence_monthly,
      RecurrenceFrequency.yearly => l10n.recurrence_yearly,
    };
  }
}
