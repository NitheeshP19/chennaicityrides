import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme.dart';
import '../services/supabase_service.dart';

class TrackingView extends StatefulWidget {
  final String tripId;

  const TrackingView({super.key, required this.tripId});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking: ${widget.tripId}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: EmeraldOrbitTheme.surfaceWhite,
        foregroundColor: EmeraldOrbitTheme.textPrimary,
        elevation: 1,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabaseService.streamDriverLocation(widget.tripId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load driver location right now.'),
            );
          }

          LatLng? currentLocation;
          String lastUpdated = 'Waiting for first GPS ping';

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!.first;
            final lat = _readCoordinate(data['latitude']);
            final lng = _readCoordinate(data['longitude']);
            lastUpdated = data['updated_at']?.toString() ?? lastUpdated;

            if (lat != null && lng != null) {
              currentLocation = LatLng(lat, lng);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.move(currentLocation!, 15.0);
              });
            }
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      currentLocation ?? const LatLng(13.0827, 80.2707),
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.chennaicityrides.admin',
                  ),
                  if (currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: currentLocation,
                          width: 60,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              color: EmeraldOrbitTheme.premiumOrange.withValues(
                                alpha: 0.2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.airport_shuttle,
                                color: EmeraldOrbitTheme.primaryGreen,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (currentLocation == null)
                Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_searching_rounded,
                            size: 32,
                            color: EmeraldOrbitTheme.primaryGreen,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No live location yet.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ask the driver to open the tracker link so GPS updates can start.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            lastUpdated,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Last update: $lastUpdated',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
