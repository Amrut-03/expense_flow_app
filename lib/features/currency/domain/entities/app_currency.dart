import 'package:equatable/equatable.dart';

class AppCurrency extends Equatable {
  final String code;
  final String symbol;
  final String name;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  @override
  List<Object?> get props => [code];
}

const supportedCurrencies = [
  AppCurrency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  AppCurrency(code: 'USD', symbol: '\$', name: 'US Dollar'),
  AppCurrency(code: 'EUR', symbol: '€', name: 'Euro'),
  AppCurrency(code: 'GBP', symbol: '£', name: 'British Pound'),
];
