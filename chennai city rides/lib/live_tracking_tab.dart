import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Colors {
  static const primary = Color(0xFF004C22);
  static const primaryContainer = Color(0xFF166534);
  static const secondary = Color(0xFF15803D);
  static const surface = Color(0xFFF8F9FA);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF404940);
  static const outlineVariant = Color(0xFFBFC9BD);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFA6F4B5);
}

class LiveTrackingTab extends StatefulWidget {
  const LiveTrackingTab({super.key});

  @override
  State<LiveTrackingTab> createState() => _LiveTrackingTabState();
}

class _LiveTrackingTabState extends State<LiveTrackingTab>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  String? _selectedTripId;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  double? _readCoord(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  String _display(dynamic v, String fallback) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty || s == 'null') ? fallback : s;
  }

  Color _statusDotColor(String status) {
    switch (status.toLowerCase()) {
      case 'allotted':
        return _Colors.primaryContainer;
      case 'completed':
        return _Colors.onSurfaceVariant;
      default:
        return _Colors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: _Colors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _selectedTripId != null
              ? _buildMapView(_selectedTripId!)
              : _buildTripList(userId),
        ),
      ),
    );
  }

  // ─── Trip List ───────────────────────────────────────────────
  Widget _buildTripList(String? userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _client
                .from('trip_requests')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: _Colors.primaryContainer,
                  ),
                );
              }

              // Filter for trips with status 'Allotted' (active tracking)
              final trips = snapshot.data!
                  .where((t) =>
                      _display(t['status'], '').toLowerCase() == 'allotted')
                  .toList();

              if (trips.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: trips.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) =>
                    _buildTripCard(trips[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_Colors.primaryContainer, _Colors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: _Colors.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _Colors.onSurface,
                        letterSpacing: -0.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track your driver in real-time',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: _Colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _Colors.primaryFixed.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.location_searching_rounded,
                color: _Colors.primaryContainer,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No active trips',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _Colors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once a driver is allotted and enables GPS,\nyou\'ll see live tracking here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: _Colors.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final tripId = trip['id']?.toString() ?? '';
    final status = _display(trip['status'], 'New');
    final driverName = _display(trip['driver_name'], 'Driver pending');
    final vehicle = _display(trip['vehicle_type'], 'Vehicle');
    final pickup = _display(trip['pickup_location'], 'Pickup');
    final dropoff = _display(trip['dropoff_location'], 'Dropoff');

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTripId = tripId);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _Colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _Colors.onSurface.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_Colors.primaryContainer, _Colors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.airport_shuttle_rounded,
                    color: _Colors.onPrimary,
                    size: 24,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _Colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$vehicle • Trip #${tripId.length > 6 ? tripId.substring(0, 6) : tripId}',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: _Colors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusDotColor(status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _statusDotColor(status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusDotColor(status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: _Colors.outlineVariant.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.my_location_rounded,
                  size: 14,
                  color: _Colors.primaryContainer.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pickup,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: _Colors.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: _Colors.secondary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dropoff,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: _Colors.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_Colors.primaryContainer, _Colors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_rounded,
                    size: 16,
                    color: _Colors.onPrimary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Track on Map',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _Colors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Map View ────────────────────────────────────────────────
  Widget _buildMapView(String tripId) {
    return Column(
      children: [
        // Top bar with back button
        Padding(
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
                  onPressed: () {
                    setState(() => _selectedTripId = null);
                  },
                  icon:
                      const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                  color: _Colors.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          color: _Colors.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Trip #${tripId.length > 8 ? tripId.substring(0, 8) : tripId}...',
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
        ),

        // Map
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _client
                .from('driver_locations')
                .stream(primaryKey: ['trip_id'])
                .eq('trip_id', tripId),
            builder: (context, locationSnap) {
              final location =
                  locationSnap.hasData && locationSnap.data!.isNotEmpty
                      ? locationSnap.data!.first
                      : null;
              final lat = _readCoord(location?['latitude']);
              final lng = _readCoord(location?['longitude']);
              final hasLive = lat != null && lng != null;
              final pos = hasLive
                  ? LatLng(lat, lng)
                  : const LatLng(13.0827, 80.2707);

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: pos,
                          initialZoom: hasLive ? 15.0 : 12.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.chennaicityrides.app',
                          ),
                          if (hasLive)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: pos,
                                  width: 72,
                                  height: 72,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _Colors.secondary
                                          .withValues(alpha: 0.18),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.airport_shuttle_rounded,
                                        size: 32,
                                        color: _Colors.primaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!hasLive)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _Colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  _Colors.onSurface.withValues(alpha: 0.05),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    _Colors.primaryContainer,
                                    _Colors.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.location_searching_rounded,
                                color: _Colors.onPrimary,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Waiting for GPS',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _Colors.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'The driver hasn\'t opened the tracker yet. '
                              'Live location will appear automatically.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                color: _Colors.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Last update badge
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _Colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _Colors.onSurface.withValues(alpha: 0.08),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: hasLive
                                  ? _Colors.primaryContainer
                                  : _Colors.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasLive ? 'Live' : 'Waiting',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: hasLive
                                  ? _Colors.primaryContainer
                                  : _Colors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
