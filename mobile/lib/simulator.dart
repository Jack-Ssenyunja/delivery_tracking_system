import 'dart:async';
import 'dart:math';
import 'api.dart';

typedef LocationCallback = void Function(double lat, double lng);

class MovementSimulator {
  MovementSimulator({
    required this.startLat,
    required this.startLng,
    required this.destLat,
    required this.destLng,
    required this.deliveryId,
    required this.riderId,
    this.speedMps = 5.0,
    this.interval = const Duration(seconds: 2),
    required this.onLocationUpdate,
  });

  final double startLat;
  final double startLng;
  final double destLat;
  final double destLng;
  final String deliveryId;
  final String riderId;
  final double speedMps;
  final Duration interval;
  final LocationCallback onLocationUpdate;

  double _lat = 0;
  double _lng = 0;
  Timer? _timer;
  bool _running = false;

  bool get isRunning => _running;

  void start() {
    if (_running) return;
    _lat = startLat;
    _lng = startLng;
    _running = true;
    _tick();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  Future<void> _tick() async {
    final dist = _haversineM(_lat, _lng, destLat, destLng);
    if (dist < 5) {
      _lat = destLat;
      _lng = destLng;
      onLocationUpdate(_lat, _lng);
      await DeliveryApi.locationPing(
        deliveryId: deliveryId,
        riderId: riderId,
        lat: _lat,
        lng: _lng,
      );
      stop();
      return;
    }

    final step = speedMps * interval.inMilliseconds / 1000;
    final bearing = _bearing(_lat, _lng, destLat, destLng);
    final moved = _movePoint(_lat, _lng, bearing, step);
    _lat = moved.$1;
    _lng = moved.$2;

    onLocationUpdate(_lat, _lng);
    await DeliveryApi.locationPing(
      deliveryId: deliveryId,
      riderId: riderId,
      lat: _lat,
      lng: _lng,
    );
  }

  static double _haversineM(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dphi = (lat2 - lat1) * pi / 180;
    final dlambda = (lng2 - lng1) * pi / 180;
    final a = sin(dphi / 2) * sin(dphi / 2) +
        cos(phi1) * cos(phi2) * sin(dlambda / 2) * sin(dlambda / 2);
    return 2 * r * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _bearing(double lat1, double lng1, double lat2, double lng2) {
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dlambda = (lng2 - lng1) * pi / 180;
    final y = sin(dlambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dlambda);
    return atan2(y, x);
  }

  static (double, double) _movePoint(
    double lat, double lng, double bearing, double distanceM,
  ) {
    const r = 6371000.0;
    final phi1 = lat * pi / 180;
    final lambda1 = lng * pi / 180;
    final phi2 = asin(
      sin(phi1) * cos(distanceM / r) +
          cos(phi1) * sin(distanceM / r) * cos(bearing),
    );
    final lambda2 = lambda1 +
        atan2(
          sin(bearing) * sin(distanceM / r) * cos(phi1),
          cos(distanceM / r) - sin(phi1) * sin(phi2),
        );
    return (phi2 * 180 / pi, lambda2 * 180 / pi);
  }
}
