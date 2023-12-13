import 'package:binance_demo/core/data/remote/binance/binance_interface.dart';
import 'package:binance_demo/core/data/remote/binance/binance_service.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BinanceRepositoryImpl implements BinanceRepository {
  final BinanceService _binanceService;
  BinanceRepositoryImpl(this._binanceService);
  @override
  Future<void> establishSocketConnection(
      {required String symbol, required String interval}) async {
    return _binanceService.establishSocketConnection(
        symbol: symbol, interval: interval);
  }

  @override
  Future<List<Candle>> getCandles(
      {required String symbol, required String interval, int? endTime}) async {
    return _binanceService.getCandles(symbol: symbol, interval: interval);
  }

  @override
  Future<List<String>> getSymbols() async {
    return _binanceService.getSymbols();
  }
}

final binanceRepositoryProvider = Provider<BinanceRepository>((ref) {
  return BinanceRepositoryImpl(ref.read(binanceServiceProvider));
});
