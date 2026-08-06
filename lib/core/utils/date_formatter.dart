import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String expenseDate(DateTime date) {
    return DateFormat('dd MMM, hh:mm a').format(date);
  }
}
