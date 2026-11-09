import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/spending_event.dart';
import '../../domain/usecases/spending_event_usecases.dart';

String eventKindLabel(AppLocalizations l10n, SpendingEventKind kind) =>
    switch (kind) {
      SpendingEventKind.festival => l10n.events_kindFestival,
      SpendingEventKind.wedding => l10n.events_kindWedding,
      SpendingEventKind.trip => l10n.events_kindTrip,
      SpendingEventKind.other => l10n.events_kindOther,
    };

String eventErrorLabel(AppLocalizations l10n, EventValidationError error) =>
    switch (error) {
      EventValidationError.name => l10n.events_errorName,
      EventValidationError.budget => l10n.addExpense_validAmount,
      EventValidationError.dates => l10n.events_errorDates,
    };

/// Common travel currencies offered for trips (filtered to those with a
/// known exchange rate when rates are loaded).
const tripCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'AED',
  'THB',
  'SGD',
  'MYR',
  'JPY',
  'AUD',
  'CAD',
  'CHF',
  'LKR',
  'NPR',
  'IDR',
  'VND',
  'SAR',
  'QAR',
];
