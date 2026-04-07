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
  late final TextEditingController _searchController;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 300,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search customer or location...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: EmeraldOrbitTheme.surfaceGray,
              ),
            ),
          ),
          const SizedBox(width: 16),
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

                final rawTrips = snapshot.data ?? [];

                // 1. Filter by Status & Search
                final searchText = _searchController.text.toLowerCase();
                final trips = rawTrips.where((trip) {
                  final statusMatch =
                      _selectedStatus == 'all' ||
                      trip['status'] == _selectedStatus;

                  final customerName =
                      trip['customer_name']?.toString().toLowerCase() ?? '';
                  final pickup =
                      trip['pickup_location']?.toString().toLowerCase() ?? '';
                  final dropoff =
                      trip['dropoff_location']?.toString().toLowerCase() ?? '';

                  final searchMatch =
                      searchText.isEmpty ||
                      customerName.contains(searchText) ||
                      pickup.contains(searchText) ||
                      dropoff.contains(searchText);

                  return statusMatch && searchMatch;
                }).toList();

                if (rawTrips.isEmpty) {
                  return const Center(child: Text('No trip requests yet.'));
                }

                return Column(
                  children: [
                    _buildFilterRow(),
                    Expanded(
                      child: trips.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.all(24),
                              itemCount: trips.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  _buildTripCard(trips[index]),
                            ),
                    ),
                  ],
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

  Widget _buildFilterRow() {
    final filters = [
      {'id': 'all', 'label': 'All Trips'},
      {'id': 'pending', 'label': 'Pending'},
      {'id': 'pending_payment', 'label': 'Awaiting Payment'},
      {'id': 'paid', 'label': 'Confirmed/Paid'},
      {'id': 'cancelled', 'label': 'Cancelled'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedStatus == filter['id'];
          return ChoiceChip(
            label: Text(filter['label']!),
            selected: isSelected,
            onSelected: (val) {
              if (val) setState(() => _selectedStatus = filter['id']!);
            },
            selectedColor: EmeraldOrbitTheme.primaryGreen.withValues(
              alpha: 0.15,
            ),
            labelStyle: TextStyle(
              color: isSelected
                  ? EmeraldOrbitTheme.primaryGreen
                  : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? EmeraldOrbitTheme.primaryGreen
                  : Colors.grey.shade300,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No matching records found.',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final isSelected = trip['id'] == _selectedTrip?['id'];
    final statusValue = _displayValue(trip['status'], 'pending');
    final isAllotted = statusValue != 'pending';
    final statusLabel = statusValue
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ""
              : "${word[0].toUpperCase()}${word.substring(1)}",
        )
        .join(' ');
    final pickup = _displayValue(trip['pickup_location'], 'Pickup pending');
    final dropoff = _displayValue(trip['dropoff_location'], 'Dropoff pending');
    final startDate = _displayValue(trip['start_date'], 'Schedule pending');
    final passengerCount = _displayValue(trip['passenger_count'], '0');
    final vehicleType = _displayValue(trip['vehicle_type'], '4+1  Car AC');
    final customerName = _displayValue(trip['customer_name'], 'Anonymous');

    return InkWell(
      onTap: () => setState(() => _selectedTrip = trip),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : EmeraldOrbitTheme.surfaceWhite.withValues(alpha: 0.8),
          border: Border.all(
            color: isSelected
                ? EmeraldOrbitTheme.primaryGreen
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 20 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EmeraldOrbitTheme.primaryGreen.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          size: 20,
                          color: EmeraldOrbitTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          vehicleType,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: isAllotted
                              ? EmeraldOrbitTheme.primaryGreen
                              : EmeraldOrbitTheme.premiumOrange,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 8,
                        color: EmeraldOrbitTheme.primaryGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pickup,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 3, top: 4, bottom: 4),
                    child: SizedBox(
                      height: 12,
                      child: VerticalDivider(width: 2, thickness: 1.5),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: EmeraldOrbitTheme.premiumOrange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dropoff,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        startDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.group_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        passengerCount,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
