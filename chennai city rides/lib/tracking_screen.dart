import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Colors {
  static const primary = Color(0xFF166534);
  static const primaryContainer = Color(0xFF22C55E);
  static const secondary = Color(0xFFF97316);
  static const surface = Color(0xFFF8F9FA);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF404940);
  static const outlineVariant = Color(0xFFBFC9BD);
  static const onPrimary = Color(0xFFFFFFFF);
}

class TrackingScreen extends StatefulWidget {
  final String tripId;

  const TrackingScreen({super.key, required this.tripId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _client = Supabase.instance.client;
  final MapController _mapController = MapController();

  double? _readCoordinate(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  String _displayValue(dynamic value, String fallback) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') {
      return fallback;
    }
    return text;
  }

  String _driverInitials(Map<String, dynamic> trip) {
    final name = _displayValue(trip['driver_name'], 'Driver Pending');
    final words = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.trim().substring(0, 1).toUpperCase())
        .take(2)
        .join();
    return words.isEmpty ? 'DP' : words;
  }

  String _statusText(Map<String, dynamic> trip) {
    return _displayValue(trip['status'], 'New');
  }

  String _waitingMessage(Map<String, dynamic> trip) {
    final status = _displayValue(trip['status'], 'New').toLowerCase();
    
    if (status == 'approved') {
      return 'Quote accepted! Waiting for your driver to start the live GPS signal.';
    }
    
    final hasDriver = _displayValue(trip['driver_name'], '').isNotEmpty;
    if (hasDriver) {
      return 'Driver allotted. Live tracking will begin once the journey starts.';
    }
    
    return 'Your request is in the admin queue. A premium vehicle will be allotted shortly.';
  }

  String _lastUpdated(Map<String, dynamic>? location) {
    final value = location?['updated_at']?.toString();
    if (value == null || value.isEmpty) {
      return 'Waiting for GPS update';
    }
    return value;
  }

  void _copyText(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _Colors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _client
          .from('trip_requests')
          .stream(primaryKey: ['id'])
          .eq('id', widget.tripId),
      builder: (context, tripSnapshot) {
        final trip = tripSnapshot.hasData && tripSnapshot.data!.isNotEmpty
            ? tripSnapshot.data!.first
            : <String, dynamic>{};

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _client
              .from('driver_locations')
              .stream(primaryKey: ['trip_id'])
              .eq('trip_id', widget.tripId),
          builder: (context, locationSnapshot) {
            final location =
                locationSnapshot.hasData && locationSnapshot.data!.isNotEmpty
                ? locationSnapshot.data!.first
                : null;
            final lat = _readCoordinate(location?['latitude']);
            final lng = _readCoordinate(location?['longitude']);
            final hasLiveLocation = lat != null && lng != null;
            final currentPosition = hasLiveLocation
                ? LatLng(lat, lng)
                : const LatLng(13.0827, 80.2707);

            if (hasLiveLocation) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.move(currentPosition, 15.0);
              });
            }

            return Scaffold(
              backgroundColor: _Colors.surface,
              body: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentPosition,
                      initialZoom: hasLiveLocation ? 15.0 : 12.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.chennaicityrides.app',
                      ),
                      if (hasLiveLocation)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: currentPosition,
                              width: 72,
                              height: 72,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _Colors.secondary.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.airport_shuttle_rounded,
                                    size: 32,
                                    color: _Colors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        _buildTopBar(trip),
                        const SizedBox(height: 16),
                        Expanded(
                          child: hasLiveLocation
                              ? const SizedBox.shrink()
                              : Center(child: _buildWaitingCard(trip)),
                        ),
                        _buildBottomSheet(trip, location, hasLiveLocation),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopBar(Map<String, dynamic> trip) {
    final status = _statusText(trip);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _Colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _Colors.onSurface.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              color: _Colors.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _Colors.surfaceContainerLowest.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: status == 'Allotted'
                          ? _Colors.primaryContainer
                          : _Colors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Trip ${widget.tripId} - $status',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _Colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCard(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _Colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _Colors.onSurface.withValues(alpha: 0.05),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_Colors.primaryContainer, _Colors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.location_searching_rounded,
              color: _Colors.onPrimary,
              size: 34,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Live tracking will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _Colors.onSurface,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _waitingMessage(trip),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: _Colors.onSurfaceVariant.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(
    Map<String, dynamic> trip,
    Map<String, dynamic>? location,
    bool hasLiveLocation,
  ) {
    final driverName = _displayValue(trip['driver_name'], 'Driver pending');
    final driverPhone = _displayValue(
      trip['driver_phone'],
      'Will appear after allotment',
    );
    final vehicle = _displayValue(trip['vehicle_type'], 'Vehicle pending');
    final pickup = _displayValue(trip['pickup_location'], 'Pickup pending');
    final dropoff = _displayValue(trip['dropoff_location'], 'Dropoff pending');
    final price = _displayValue(trip['price'], 'Pending');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: _Colors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _Colors.onSurface.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: _Colors.outlineVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_Colors.primaryContainer, _Colors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _driverInitials(trip),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: _Colors.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _Colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLiveLocation ? 'Live GPS active' : _statusText(trip),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: _Colors.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copyText(widget.tripId, 'Trip ID copied.'),
                icon: const Icon(Icons.copy_rounded),
                color: _Colors.primary,
                tooltip: 'Copy trip ID',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Vehicle', vehicle),
          const SizedBox(height: 10),
          _buildInfoRow('Pickup', pickup),
          const SizedBox(height: 10),
          _buildInfoRow('Dropoff', dropoff),
          const SizedBox(height: 10),
          _buildInfoRow('Driver phone', driverPhone),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Trip price',
            price == 'Pending' ? price : 'INR $price',
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Last update', _lastUpdated(location)),
          if (_displayValue(trip['driver_phone'], '').isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _copyText(
                  _displayValue(trip['driver_phone'], ''),
                  'Driver phone copied.',
                ),
                icon: const Icon(Icons.phone_rounded),
                label: const Text('Copy driver phone'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _Colors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
