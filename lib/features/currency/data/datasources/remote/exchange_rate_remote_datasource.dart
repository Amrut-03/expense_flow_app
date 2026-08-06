import 'package:dio/dio.dart';

import '../../../../../core/error/error_formatter.dart';
import '../../../../../core/error/exceptions.dart';
import '../../models/exchange_rate_model.dart';

abstract class ExchangeRateRemoteDataSource {
  Future<ExchangeRateModel> getRates();
}

class ExchangeRateRemoteDataSourceImpl implements ExchangeRateRemoteDataSource {
  final Dio dio;

  ExchangeRateRemoteDataSourceImpl(this.dio);

  @override
  Future<ExchangeRateModel> getRates() async {
    try {
      final response = await dio.get(
        'https://api.frankfurter.dev/v1/latest',
        queryParameters: {'base': 'USD'},
      );

      final data = response.data as Map<String, dynamic>;

      final model = ExchangeRateModel.fromJson(data);

      model.rates['USD'] = 1.0;

      return model;
    } on DioException catch (e) {
      throw ServerException(friendlyError(e));
    } on Exception catch (e) {
      throw ServerException(friendlyError(e));
    }
  }
}
