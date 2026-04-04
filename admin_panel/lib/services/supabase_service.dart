import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // Stream new trip requests
  Stream<List<Map<String, dynamic>>> streamTrips() {
    return _client
        .from('trip_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Allot a vehicle and driver to a trip
  Future<void> allotTrip({
    required String tripId,
    required String driverName,
    required String driverPhone,
    required String vehicleType,
    required double price,
  }) async {
    final response = await _client.functions.invoke(
      'allot-trip',
      body: {
        'trip_id': tripId,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'vehicle_type': vehicleType,
        'price': price,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to allot trip: ${response.data}');
    }
  }

  // Stream driver locations for a specific trip
  Stream<List<Map<String, dynamic>>> streamDriverLocation(String tripId) {
    return _client
        .from('driver_locations')
        .stream(primaryKey: ['trip_id'])
        .eq('trip_id', tripId);
  }
}

final supabaseService = SupabaseService();
