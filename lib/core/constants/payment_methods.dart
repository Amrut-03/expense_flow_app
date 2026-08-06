import '../../l10n/app_localizations.dart';

class PaymentMethods {
  static const List<String> all = [
    'Cash',
    'Card',
    'UPI',
    'Bank Transfer',
    'Other',
  ];

  static const Map<String, String> emojis = {
    'Cash': '💵',
    'Card': '💳',
    'UPI': '📱',
    'Bank Transfer': '🏦',
    'Other': '💸',
  };

  static String localizedLabel(AppLocalizations l10n, String method) {
    switch (method) {
      case 'Cash':
        return l10n.payment_cash;
      case 'Card':
        return l10n.payment_card;
      case 'UPI':
        return l10n.payment_upi;
      case 'Bank Transfer':
        return l10n.payment_bankTransfer;
      default:
        return l10n.payment_other;
    }
  }
}
