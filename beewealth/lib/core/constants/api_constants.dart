class ApiConstants {
  static const String baseUrl = 'http://api.beewealth.kalique.xyz/api';
  
  // Auth
  static const String login = '/login/';
  static const String register = '/register/';
  static const String verifyOtp = '/verify-otp/';
  
  // Profile & Wallet
  static const String me = '/me/';
  
  // History & Charting
  static const String ledger = '/ledger/';
  static const String performanceChart = '/pl/';
  
  // Fund Requests
  static const String investmentRequests = '/investment-requests/';
  static const String withdrawals = '/withdrawals/';
  
  // Admin
  static const String users = '/users/';
  
  // Public Paper Trading
  static const String paperWsPositions = 'wss://api.kalique.xyz:443/api/public/paper/ws/positions';
  static const String paperTodayOrders = 'https://api.kalique.xyz/api/public/paper/today-orders';
  
  // Public Legal
  static const String terms = '/terms/';
}
