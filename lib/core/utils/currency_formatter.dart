import 'package:intl/intl.dart';

abstract final class CurrencyFormatter {
  static final NumberFormat _format = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num amount) => _format.format(amount);
}
