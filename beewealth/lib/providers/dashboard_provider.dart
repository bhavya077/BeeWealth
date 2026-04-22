import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../core/constants/api_constants.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  DashboardData? _dashboardData;
  List<LedgerEntry> _ledgerEntries = [];
  List<PerformanceData> _performanceChart = [];
  List<FundRequest> _investmentHistory = [];
  List<FundRequest> _withdrawalHistory = [];
  
  bool _isLoading = false;
  String? _error;

  DashboardData? get dashboardData => _dashboardData;
  List<LedgerEntry> get ledgerEntries => _ledgerEntries;
  List<PerformanceData> get performanceChart => _performanceChart;
  List<FundRequest> get investmentHistory => _investmentHistory;
  List<FundRequest> get withdrawalHistory => _withdrawalHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    if (_error == value) return;
    _error = value;
    notifyListeners();
  }

  Future<void> fetchDashboard() async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _apiService.get(ApiConstants.me);
      _dashboardData = DashboardData.fromJson(response);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> fetchLedger() async {
    _setLoading(true);
    _setError(null);
    try {
      final List<dynamic> response = await _apiService.get(ApiConstants.ledger);
      _ledgerEntries = response.map((e) => LedgerEntry.fromJson(e)).toList();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> fetchPerformance() async {
    _setLoading(true);
    _setError(null);
    try {
      final List<dynamic> response = await _apiService.get(ApiConstants.performanceChart);
      _performanceChart = response.map((e) => PerformanceData.fromJson(e)).toList();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> fetchInvestmentHistory() async {
    _setLoading(true);
    _setError(null);
    try {
      final List<dynamic> response = await _apiService.get(ApiConstants.investmentRequests);
      _investmentHistory = response.map((e) => FundRequest.fromJson(e)).toList();
      _setLoading(false);
    } catch (e) {
      if (_investmentHistory.isEmpty) _setError('Failed to load deposit history');
      _setLoading(false);
    }
  }

  Future<void> fetchWithdrawalHistory() async {
    _setLoading(true);
    _setError(null);
    try {
      final List<dynamic> response = await _apiService.get(ApiConstants.withdrawals);
      _withdrawalHistory = response.map((e) => FundRequest.fromJson(e)).toList();
      _setLoading(false);
    } catch (e) {
      if (_withdrawalHistory.isEmpty) _setError('Failed to load withdrawal history');
      _setLoading(false);
    }
  }

  Future<bool> requestInvestment(double amount) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.post(ApiConstants.investmentRequests, {'amount': amount});
      await fetchInvestmentHistory(); // Refresh history
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> requestWithdrawal(double amount) async {
    _setLoading(true);
    _setError(null);
    try {
      await _apiService.post(ApiConstants.withdrawals, {'amount': amount});
      await fetchWithdrawalHistory(); // Refresh history
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
