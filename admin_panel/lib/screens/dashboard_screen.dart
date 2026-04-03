import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/allotment_sidebar.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _selectedTrip;

  String _displayValue(dynamic value, String fallback) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') {
      return fallback;
    }
    return text;
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.hub_rounded,
              color: EmeraldOrbitTheme.primaryGreen,
            ),
            const SizedBox(width: 8),
            Text(
              'Chennai City Rides Admin',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: EmeraldOrbitTheme.primaryGreen,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
          const SizedBox(width: 24),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabaseService.streamTrips(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Unable to load trip requests right now.'),
                  );
                }

                final trips = snapshot.data ?? [];
                if (trips.isEmpty) {
                  return const Center(child: Text('No trip requests yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: trips.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    final isSelected = trip['id'] == _selectedTrip?['id'];
                    final status = _displayValue(trip['status'], 'New');
                    final isAllotted = status == 'Allotted' || status == 'Pending_Payment';
                    final pickup = _displayValue(
                      trip['pickup_location'],
                      'Pickup pending',
                    );
                    final dropoff = _displayValue(
                      trip['dropoff_location'],
                      'Dropoff pending',
                    );
                    final startDate = _displayValue(
                      trip['start_date'],
                      'Schedule pending',
                    );
                    final passengerCount = _displayValue(
                      trip['passenger_count'],
                      '0',
                    );
                    final vehicleType = _displayValue(
                      trip['vehicle_type'],
                      'Standard Car',
                    );

                    return InkWell(
                      onTap: () => setState(() => _selectedTrip = trip),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? EmeraldOrbitTheme.primaryGreen.withValues(
                                  alpha: 0.05,
                                )
                              : EmeraldOrbitTheme.surfaceWhite,
                          border: Border.all(
                            color: isSelected
                                ? EmeraldOrbitTheme.primaryGreen
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0a000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        vehicleType,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isAllotted
                                              ? EmeraldOrbitTheme.primaryGreen
                                                    .withValues(alpha: 0.1)
                                              : EmeraldOrbitTheme.premiumOrange
                                                    .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: isAllotted
                                                ? EmeraldOrbitTheme.primaryGreen
                                                : EmeraldOrbitTheme
                                                      .premiumOrange,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$pickup -> $dropoff',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: EmeraldOrbitTheme.textPrimary
                                              .withValues(alpha: 0.8),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Date: $startDate | Passengers: $passengerCount',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: isSelected
                                  ? EmeraldOrbitTheme.primaryGreen
                                  : Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedTrip != null)
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    spreadRadius: -5,
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: AllotmentSidebar(
                key: ValueKey(_selectedTrip!['id']),
                tripData: _selectedTrip!,
                onClosed: () => setState(() => _selectedTrip = null),
              ),
            ),
        ],
      ),
    );
  }
}
