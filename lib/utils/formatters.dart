import 'package:intl/intl.dart';

class Formatters {
  static final currencyFormat = NumberFormat.currency(symbol: '\$');
  static final dateFormat = DateFormat('MMM dd, yyyy');
}