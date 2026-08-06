import 'package:equatable/equatable.dart';

class ExchangeRateEntity extends Equatable {
  final Map<String, double> rates;

  const ExchangeRateEntity(this.rates);

  @override
  List<Object?> get props => [rates];
}
