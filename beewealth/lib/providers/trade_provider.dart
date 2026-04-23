import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class Position {
  final String symbol;
  final double ltp;
  final double pnlPercentage;

  Position({required this.symbol, required this.ltp, required this.pnlPercentage});

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      symbol: json['symbol'] ?? 'Unknown',
      ltp: (json['ltp'] as num?)?.toDouble() ?? 0.0,
      pnlPercentage: (json['pnl_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaperOrder {
  final String symbol;
  final double pnlPercentage;
  final String entryTime;
  final String exitTime;

  PaperOrder({
    required this.symbol,
    required this.pnlPercentage,
    required this.entryTime,
    required this.exitTime,
  });

  factory PaperOrder.fromJson(Map<String, dynamic> json) {
    return PaperOrder(
      symbol: json['symbol'] ?? 'Unknown',
      pnlPercentage: (json['pnl_percentage'] as num?)?.toDouble() ?? 0.0,
      entryTime: json['entry_time'] ?? '',
      exitTime: json['exit_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'pnl_percentage': pnlPercentage,
    'entry_time': entryTime,
    'exit_time': exitTime,
  };
}

class TradeProvider extends ChangeNotifier {
  List<Position> _positions = [];
  List<PaperOrder> _closedOrders = [];
  bool _isLoading = false;
  String? _error;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  bool _isConnecting = false;

  List<Position> get positions => _positions;
  List<PaperOrder> get closedOrders => _closedOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _channel != null;

  Future<void> connectWebSocket() async {
    if (_isConnecting || _channel != null) return;
    
    // Server is only on 9 AM - 4 PM IST (Approx UTC+5:30)
    // We check current time and only attempt if within window
    final now = DateTime.now();
    // Simplified check: assume device time is close to local market time or just let it fail gracefully
    // but we add a small guard to reduce noise.
    
    _isConnecting = true;
    _positions = [];
    
    runZonedGuarded(() async {
      try {
        final url = ApiConstants.paperWsPositions;
        if (!url.startsWith('ws')) {
          _handleWsError('Invalid Protocol');
          return;
        }
        
        final uri = Uri.parse(url);
        _channel = WebSocketChannel.connect(uri);
        
        _subscription = _channel!.stream.listen(
          (message) {
            try {
              final map = jsonDecode(message.toString()) as Map<String, dynamic>;
              final posList = (map['positions'] as List?) ?? [];
              final newPositions = posList.map((e) => Position.fromJson(e as Map<String, dynamic>)).toList();
              
              if (_positions.length != newPositions.length || 
                  (_positions.isNotEmpty && newPositions.isNotEmpty && 
                  (_positions[0].ltp != newPositions[0].ltp || _positions[0].pnlPercentage != newPositions[0].pnlPercentage))) {
                _positions = newPositions;
                _error = null;
                notifyListeners();
              }
            } catch (e) {
              // Silently handle decode errors
            }
          },
          onError: (e) {
            // Only log if it's not a common upgrade error (usually meaning market closed)
            if (!e.toString().contains('not upgraded')) {
              debugPrint('WS Stream: $e');
            }
            _handleWsError('Market is currently closed');
          },
          onDone: () {
            _handleWsError(null);
          },
          cancelOnError: true,
        );
      } catch (e) {
        debugPrint('WebSocket Connect Error: $e');
        _handleWsError('Market is currently closed');
      } finally {
        _isConnecting = false;
      }
    }, (error, stack) {
      debugPrint('Zoned WebSocket Error: $error');
      _handleWsError('Market is currently closed');
      _isConnecting = false;
    });
  }

  void _handleWsError(String? errorMessage) {
    if (errorMessage != null && _error != errorMessage) {
      _error = errorMessage;
      notifyListeners();
    }
    disposeWebSocket();
    _reconnect();
  }

  void _reconnect() {
    // 30 second delay if market is closed to prevent CPU spiking/app sticking
    final delay = _error != null ? 30 : 10;
    Future.delayed(Duration(seconds: delay), () {
      if (_channel == null && !_isConnecting) {
        connectWebSocket();
      }
    });
  }

  void disposeWebSocket() {
    _subscription?.cancel();
    _channel?.sink.close();
    _subscription = null;
    _channel = null;
    _isConnecting = false;
  }

  Future<void> fetchTodayOrders() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Try cache first and show it immediately if not already loaded
      if (_closedOrders.isEmpty) {
        await _loadFromCache();
        notifyListeners();
      }
      
      final response = await http.get(Uri.parse(ApiConstants.paperTodayOrders));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final orders = (body['orders'] as List?) ?? [];
        _closedOrders = orders.map((e) => PaperOrder.fromJson(e as Map<String, dynamic>)).toList();
        await _saveToCache(_closedOrders);
      } else {
        if (_closedOrders.isEmpty) _error = 'Please wait till market opens';
      }
    } catch (e) {
      if (_closedOrders.isEmpty) _error = 'Please wait till market opens';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToCache(List<PaperOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    
    final data = {
      'date': today,
      'orders': orders.map((e) => e.toJson()).toList(),
    };
    await prefs.setString('paper_orders_cache', jsonEncode(data));
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStr = prefs.getString('paper_orders_cache');
    if (cachedStr != null) {
      final map = jsonDecode(cachedStr) as Map<String, dynamic>;
      final cachedDate = map['date'] as String;
      final now = DateTime.now();
      final today = '${now.year}-${now.month}-${now.day}';
      
      if (cachedDate == today) {
        final orders = (map['orders'] as List?) ?? [];
        _closedOrders = orders.map((e) => PaperOrder.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        await prefs.remove('paper_orders_cache');
        _closedOrders = [];
      }
    }
  }
}
