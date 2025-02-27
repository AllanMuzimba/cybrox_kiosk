import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class CurrencyConverter {
  static final supabase = Supabase.instance.client;
  
  // Cache exchange rates for 1 hour
  static Map<String, double> _rates = {'USD': 1.0};  // Default USD rate
  static DateTime? _lastUpdate;

  static Future<void> updateRates() async {
    if (_lastUpdate != null && 
        DateTime.now().difference(_lastUpdate!).inHours < 1) {
      return;
    }

    try {
      final response = await supabase
          .from('exchange_rates')
          .select()
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        _rates = Map<String, double>.from(response[0]['rates']);
      }
      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error updating exchange rates: $e');
      // Continue with default USD rate
    }
  }

  static double convert(double amount, String from, String to) {
    if (from == to) return amount;
    if (from == 'USD') return amount * (_rates[to] ?? 1.0);
    if (to == 'USD') return amount / (_rates[from] ?? 1.0);
    return amount / (_rates[from] ?? 1.0) * (_rates[to] ?? 1.0);
  }
} 