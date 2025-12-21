import 'package:intl/intl.dart';

class AppFormatters {
  static String rupiah(num value) {
    if (value == 0) return 'Rp 0';

    // Manual implementation if intl is not desired, but intl is robust.
    // However, to strictly follow user request of "simple dot separator":
    // The standard ID format uses dots for thousands and comma for decimals.
    // We assume integer prices for simplicity based on context, or handle decimals if needed.

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }
}
