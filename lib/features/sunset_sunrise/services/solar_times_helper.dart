import 'package:solar_calculator/solar_calculator.dart';

/// Tính bình minh / hoàng hôn hôm nay (theo giờ địa phương máy).
class SolarTimesHelper {
  SolarTimesHelper._();

  static DateTime? sunriseLocal(
      DateTime date, double latitude, double longitude) {
    try {
      final local = DateTime(date.year, date.month, date.day, 12);
      final instant = Instant.fromDateTime(local);
      final calc = SolarCalculator(instant, latitude, longitude);
      return calc.sunriseTime.toUtcDateTime().toLocal();
    } catch (_) {
      return null;
    }
  }

  static DateTime? sunsetLocal(
      DateTime date, double latitude, double longitude) {
    try {
      final local = DateTime(date.year, date.month, date.day, 12);
      final instant = Instant.fromDateTime(local);
      final calc = SolarCalculator(instant, latitude, longitude);
      return calc.sunsetTime.toUtcDateTime().toLocal();
    } catch (_) {
      return null;
    }
  }
}
