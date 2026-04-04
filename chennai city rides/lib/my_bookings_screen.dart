import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tracking_screen.dart';

class _Colors {
  static const primary = Color(0xFF004C22);
  static const primaryContainer = Color(0xFF166534);
  static const secondary = Color(0xFFF97316);
  static const secondaryContainer = Color(0xFFFD761A);
  static const surface = Color(0xFFF8F9FA);
  static const surfaceContainerLow = Color(0xFFF3F4F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerHigh = Color(0xFFE7E8E9);
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF404940);
  static const outlineVariant = Color(0xFFBFC9BD);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFA6F4B5);
  static const inProgress = Color(0xFF3B82F6);
  static const completed = Color(0xFF10B981);
}

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  StreamSubscription<List<Map<String, dynamic>>>? _statusSubscription;
  final Map<String, String> _lastKnownStatuses = {};

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

    _setupStatusListener();
  }

  void _setupStatusListener() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _statusSubscription = _client
        .from('trip_requests')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((trips) {
      if (!mounted) return;

      for (final trip in trips) {
        final id = trip['id'].toString();
        final status = trip['status']?.toString().toLowerCase();
        final lastStatus = _lastKnownStatuses[id];

        // Notify if it moves from pending to pending_payment
        if (lastStatus == 'pending' && status == 'pending_payment') {
          _showNotification('New quote received for your ride!');
        }

        _lastKnownStatuses[id] = status ?? '';
      }
    });
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _Colors.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  String _display(dynamic v, String fallback) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty || s == 'null') ? fallback : s;
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $hour:$minute $period';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF6B7280);
      case 'pending_payment':
        return _Colors.secondary;
      case 'approved':
        return _Colors.primaryContainer;
      case 'assigned':
        return _Colors.primaryContainer;
      case 'in_progress':
        return _Colors.inProgress;
      case 'completed':
        return _Colors.completed;
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.timer_outlined;
      case 'pending_payment':
        return Icons.request_quote_rounded;
      case 'approved':
        return Icons.check_circle_rounded;
      case 'assigned':
        return Icons.person_pin_circle_rounded;
      case 'in_progress':
        return Icons.local_shipping_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  IconData _vehicleIcon(String vehicle) {
    switch (vehicle.toLowerCase()) {
      case 'car':
        return Icons.directions_car_rounded;
      case 'suv':
        return Icons.local_taxi_rounded;
      case '12-seater':
        return Icons.airport_shuttle_rounded;
      case '24-seater':
        return Icons.directions_bus_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  void _copyTripId(String tripId) {
    Clipboard.setData(ClipboardData(text: tripId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip ID copied'),
        backgroundColor: _Colors.primaryContainer,
      ),
    );
  }

  Future<void> _updateTripStatus(String tripId, String newStatus) async {
    try {
      await _client
          .from('trip_requests')
          .update({'status': newStatus}).eq('id', tripId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip ${newStatus.replaceAll('_', ' ')} successfully'),
          backgroundColor: newStatus == 'cancelled' ? Colors.red : _Colors.primaryContainer,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update trip. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(child: _buildBookingsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
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
              Icons.receipt_long_rounded,
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
                  'My Bookings',
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
                  'Your ride history',
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
    );
  }

  Widget _buildBookingsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
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

        final trips = snapshot.data!;

        if (trips.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          itemCount: trips.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) =>
              _buildBookingCard(trips[index], index),
        );
      },
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
                Icons.receipt_long_outlined,
                color: _Colors.primaryContainer,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No bookings yet',
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
              'Book your first ride from the Book Ride tab.\nAll your trips will appear here.',
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

  Widget _buildBookingCard(Map<String, dynamic> trip, int index) {
    final tripId = trip['id']?.toString() ?? '';
    final status = _display(trip['status'], 'New');
    final vehicle = _display(trip['vehicle_type'], 'Vehicle');
    final pickup = _display(trip['pickup_location'], 'Pickup not set');
    final dropoff = _display(trip['dropoff_location'], 'Dropoff not set');
    final driverName = _display(trip['driver_name'], 'Driver pending');
    final price = _display(trip['price'], '');
    final createdAt = _formatDate(trip['created_at']?.toString());
    final startDate = _formatDate(trip['start_date']?.toString());
    final isActive = ['assigned', 'in_progress'].contains(status.toLowerCase());
    final isPendingPayment = status.toLowerCase() == 'pending_payment';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: isActive
            ? Border.all(
                color: _Colors.primaryContainer.withValues(alpha: 0.2),
                width: 1.5,
              )
            : null,
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
          // Header row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [_Colors.primaryContainer, _Colors.primary]
                        : [_Colors.surfaceContainerHigh, _Colors.surfaceContainerLow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _vehicleIcon(vehicle),
                  color: isActive ? _Colors.onPrimary : _Colors.onSurfaceVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _Colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: _Colors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _copyTripId(tripId),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 14,
                        color: _statusColor(status),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status),
                        ),
                      ),
                    ],
                  ),
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

          // Route info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _Colors.primaryContainer,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    color: _Colors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: _Colors.secondary.withValues(alpha: 0.8),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickup,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      dropoff,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Colors.onSurface,
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
          const SizedBox(height: 12),

          // Details row
          Row(
            children: [
              _buildDetailChip(Icons.person_rounded, driverName),
              if (price.isNotEmpty) ...[
                const SizedBox(width: 10),
                _buildDetailChip(
                    Icons.currency_rupee_rounded, 'INR $price'),
              ],
            ],
          ),

          if (startDate != '—') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDetailChip(Icons.schedule_rounded, 'Start: $startDate'),
              ],
            ),
          ],

          // Track button for active trips
          if (isActive) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackingScreen(tripId: tripId),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_Colors.secondaryContainer, _Colors.secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: _Colors.onPrimary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Track Live',
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
            ),
          ],

          // Accept/Reject buttons for Pending Payment
          if (isPendingPayment) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateTripStatus(tripId, 'cancelled'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _Colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Reject',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _Colors.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateTripStatus(tripId, 'approved'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_Colors.primaryContainer, _Colors.primary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Accept Quote',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _Colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _Colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: _Colors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _Colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
