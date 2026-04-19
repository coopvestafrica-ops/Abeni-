import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_NG');
final NumberFormat _currencyWholeFormat = NumberFormat('#,##0', 'en_NG');

String formatNaira(num amount, {bool showDecimals = false}) {
  final formatted =
      showDecimals ? _currencyFormat.format(amount) : _currencyWholeFormat.format(amount);
  return '${AppConstants.currencySymbol}$formatted';
}

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy • hh:mm a').format(date);
}
