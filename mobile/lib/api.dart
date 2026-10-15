import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class DeliveryApi {
  static Future<List<dynamic>> getDeliveries() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/deliveries'));
    if (res.statusCode != 200) throw Exception('Failed to load deliveries');
    return jsonDecode(res.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> accept(String id) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/deliveries/$id/accept'),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> startTrip(String id) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/deliveries/$id/start'),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> handover(String id) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/deliveries/$id/handover'),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> received(String id) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/deliveries/$id/received'),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> locationPing({
    required String deliveryId,
    required String riderId,
    required double lat,
    required double lng,
  }) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/location-ping'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'delivery_id': deliveryId,
        'rider_id': riderId,
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }
}
