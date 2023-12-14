import 'dart:async';
import 'dart:convert';
import 'package:binance_demo/core/data/data.dart';
import 'package:binance_demo/core/errors/errors.dart';
import 'package:binance_demo/core/models/models.dart';
import 'package:binance_demo/presentation/states/states.dart';
import 'package:binance_demo/utils/utils.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HomeViewModel extends BaseViewModel {
  final Ref ref;
  HomeViewModel(this.ref);
  final _logger = appLogger(HomeViewModel);
  // ******************************** [VARIABLES] ************************************
  int _selectedInterval = 0;
  int get selectedInterval => _selectedInterval;
  List<SymbolResponseModel> _symbols = [];
  List<SymbolResponseModel> get symbols => _symbols;
  WebSocketChannel? _channel;
  WebSocketChannel? get channel => _channel;

  List<Candle> _candles = [];
  List<Candle> get candles => _candles;
  String _currentInterval = "1H";
  String get currentInterval => _currentInterval;
  SymbolResponseModel? _currentSymbol;
  SymbolResponseModel? get currentSymbol => _currentSymbol;
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;
  int _bottomTabIndex = 0;
  int get bottomTabIndex => _bottomTabIndex;

  CandleTickerModel? _candleStick;
  CandleTickerModel? get candleStick => _candleStick;
  OrderBook? _orderBooks;
  OrderBook? get orderBooks => _orderBooks;

  StreamController _streamController = StreamController();
  Stream get websocketStream => _streamController.stream.asBroadcastStream();
  // ***************************************[SETTERS]**********************************************
  setBottomTabIndex(int value) {
    _bottomTabIndex = value;
    notifyListeners();
  }

  setTabIndex(int v) {
    _currentTabIndex = v;
    notifyListeners();
  }

  setInterval(String value) {
    _currentInterval = value;
    notifyListeners();
  }

  setCurrentSymbol(SymbolResponseModel v) {
    _currentSymbol = v;
    notifyListeners();
  }

  setSelectedInterval(int index) {
    _selectedInterval = index;
    notifyListeners();
  }

  setCandleStick(CandleTickerModel candleT) {
    _candleStick = candleT;
    notifyListeners();
  }

  setOrderBook(OrderBook data) {
    _orderBooks = data;
    notifyListeners();
  }

  Future<void> getSymbols() async {
    _logger.d("Getting Symbols.....");
    try {
      changeState(const ViewModelState.busy());
      final result = await ref.read(binanceRepositoryProvider).getSymbols();
      changeState(const ViewModelState.idle());
      _symbols = result;
      _logger.d("Symbols Length ===> ${_symbols.length}");
      if (_symbols.isNotEmpty) {
        _currentSymbol = _symbols[0];
      }
      notifyListeners();
    } on Failure catch (e) {
      changeState(ViewModelState.error(e));
      _logger.e(e.message);
    } catch (e) {
      final err = AppError("unknown error", e.toString());
      changeState(ViewModelState.error(err));
    }
  }

  Future<void> getCandles(SymbolResponseModel symbol, String interval) async {
    _logger.d("Getting Candles......");
    try {
      changeState(const ViewModelState.busy());
      final result = await ref.read(binanceRepositoryProvider).getCandles(
            symbol: symbol.symbol,
            interval: interval.toLowerCase(),
          );
      _candles = result;
      _logger.d("Candles Response :: ${_candles.length}");
      changeState(const ViewModelState.idle());
    } on Failure catch (e) {
      changeState(ViewModelState.error(e));
      _logger.e(e.message);
    } catch (e) {
      final err = AppError("unknown error", e.toString());
      changeState(ViewModelState.error(err));
    }
  }

  initializeWebSocket() async {
    _logger.d("Initializing websocket..");
    final binanceRepository = ref.read(binanceRepositoryProvider);

    final channel = await binanceRepository.establishSocketConnection(
      interval: _currentInterval.toLowerCase(),
      symbol: _currentSymbol!.symbol,
    );
    channel.stream.listen((event) {
      _logger.d("Stream Data ===>> $event");
      _streamController.sink.add(event);
    });

    // await for (final String value in channel.stream) {
    //   final map = jsonDecode(value) as Map<String, dynamic>;
    //   final eventType = map['e'];

    //   if (eventType == 'kline') {
    //     final candleTicker = CandleTickerModel.fromJson(map);
    //     if (_candles[0].date == candleTicker.candle.date &&
    //         _candles[0].open == candleTicker.candle.open) {
    //       _candles[0] = candleTicker.candle;
    //       notifyListeners();
    //     } else if (candleTicker.candle.date.difference(candles[0].date) ==
    //         _candles[0].date.difference(candles[1].date)) {
    //       _candles.insert(0, candleTicker.candle);
    //       notifyListeners();
    //     }
    //   } else if (eventType == 'depthUpdate') {
    //     final orderBookInfo = OrderBook.fromMap(map);
    //     setOrderBook(orderBookInfo);
    //   }
    // }
  }

  listenAndUpdateChartStream() {}

  Future<void> loadMoreCandles(StreamValueDTO streamValue) async {
    try {
      final data = await ref.read(binanceRepositoryProvider).getCandles(
            symbol: streamValue.symbol.symbol,
            interval: streamValue.interval!,
            endTime: _candles.last.date.millisecondsSinceEpoch,
          );
      _candles
        ..removeLast()
        ..addAll(data);
      notifyListeners();
    } on Failure catch (e) {
      _logger.d("Custom Error fetching candles ==> ${e.message}");
    } catch (e) {
      _logger.d("Error fetching more candles ::: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
}

final homeViewModelProvider = ChangeNotifierProvider<HomeViewModel>((ref) {
  return HomeViewModel(ref);
});
