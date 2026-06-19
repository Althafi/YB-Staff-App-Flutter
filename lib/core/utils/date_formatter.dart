import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static final DateFormat _fullFormat =
      DateFormat('EEEE, d MMMM yyyy', 'id_ID');
  static final DateFormat _shortFormat = DateFormat('d MMM', 'id_ID');
  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'id_ID');

  static String toFull(DateTime date) => _fullFormat.format(date);
  static String toShort(DateTime date) => _shortFormat.format(date);
  static String toApi(DateTime date) => _apiFormat.format(date);
  static String toDisplay(DateTime date) => _displayFormat.format(date);
  static String toTime(DateTime date) => _timeFormat.format(date);

  static String toRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return _shortFormat.format(date);
  }
}
