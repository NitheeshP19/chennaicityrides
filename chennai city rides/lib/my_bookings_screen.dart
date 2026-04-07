import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'tracking_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

class _C {
  static const primary = Color(0xFF004C22);
  static const primaryContainer = Color(0xFF166534);
  static const secondary = Color(0xFF15803D);
  static const surface = Color(0xFFF8F9FA);
  static const surfaceLow = Color(0xFFF3F4F5);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFE7E8E9);
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF404940);
  static const outline = Color(0xFFBFC9BD);
  static const onPrimary = Color(0xFFFFFFFF);
  static const accent = Color(0xFFA6F4B5);
  static const inProgress = Color(0xFF3B82F6);
  static const completed = Color(0xFF10B981);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFEAB308);
}

// ─────────────────────────────────────────────────────────────────────────────
// My Bookings Screen — Supabase Realtime Stream (FIXED)
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // For status-change notifications
  StreamSubscription<List<Map<String, dynamic>>>? _notifSub;
  final Map<String, String> _prevStatuses = {};

  // ── The SINGLE realtime stream, filtered by logged-in user ──
  late final Stream<List<Map<String, dynamic>>> _tripsStream;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // ── Build the realtime stream ONCE (filtered by current user) ──
    final user = _client.auth.currentUser;
    if (user != null) {
      debugPrint('👤 USER ID: ${user.id}');
      _tripsStream = _client
          .from('trip_requests')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _setupNotifications();

      _setupNotifications();
    } else {
      // Fallback: empty stream if somehow not logged in
      _tripsStream = const Stream.empty();
    }
  }

  /// Listens for status transitions so we can show in-app toasts.
  void _setupNotifications() {
    _notifSub = _tripsStream.listen((trips) {
      if (!mounted) return;
      for (final trip in trips) {
        final id = trip['id']?.toString() ?? '';
        final status = (trip['status'] ?? '').toString().toLowerCase();
        final prev = _prevStatuses[id];

        if (prev == 'pending' && status == 'pending_payment') {
          _toast('🎉 New quote received for your ride!');
        } else if (prev == 'pending_payment' && status == 'approved') {
          _toast('✅ Quote accepted — driver on the way!');
        } else if (status == 'completed' && prev != 'completed') {
          _toast('🏁 Your trip has been completed.');
        }

        _prevStatuses[id] = status;
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  String _d(dynamic v, String fb) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty || s == 'null') ? fb : s;
  }

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final p = dt.hour >= 12 ? 'PM' : 'AM';
    return '${m[dt.month - 1]} ${dt.day}, $h:${dt.minute.toString().padLeft(2, '0')} $p';
  }

  Color _statusClr(String s) {
    switch (s.toLowerCase()) {
      case 'pending':          return const Color(0xFF6B7280);
      case 'pending_payment':  return _C.secondary;
      case 'approved':         return _C.primaryContainer;
      case 'assigned':         return _C.primaryContainer;
      case 'in_progress':      return _C.inProgress;
      case 'completed':        return _C.completed;
      case 'cancelled':        return _C.error;
      default:                 return const Color(0xFF6B7280);
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'pending':          return 'Pending';
      case 'pending_payment':  return 'Quote Ready';
      case 'approved':         return 'Approved';
      case 'assigned':         return 'Assigned';
      case 'in_progress':      return 'In Progress';
      case 'completed':        return 'Completed';
      case 'cancelled':        return 'Cancelled';
      default:                 return s;
    }
  }

  IconData _statusIco(String s) {
    switch (s.toLowerCase()) {
      case 'pending':          return Icons.timer_outlined;
      case 'pending_payment':  return Icons.request_quote_rounded;
      case 'approved':         return Icons.check_circle_rounded;
      case 'assigned':         return Icons.person_pin_circle_rounded;
      case 'in_progress':      return Icons.local_shipping_rounded;
      case 'completed':        return Icons.task_alt_rounded;
      case 'cancelled':        return Icons.cancel_rounded;
      default:                 return Icons.schedule_rounded;
    }
  }

  IconData _vehicleIco(String v) {
    switch (v.toLowerCase()) {
      case 'car':          return Icons.directions_car_rounded;
      case 'sedan':        return Icons.directions_car_rounded;
      case 'suv':          return Icons.local_taxi_rounded;
      case '12-seater':    return Icons.airport_shuttle_rounded;
      case '24-seater':    return Icons.directions_bus_rounded;
      case 'bus':          return Icons.directions_bus_rounded;
      default:             return Icons.directions_car_rounded;
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Plus Jakarta Sans'))),
        ]),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _C.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    _toast('Trip ID copied');
  }

  Future<void> _callDriver(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _toast('Cannot open dialer');
    }
  }

  Future<void> _updateStatus(String tripId, String newStatus) async {
    try {
      await _client
          .from('trip_requests')
          .update({'status': newStatus}).eq('id', tripId);
      if (!mounted) return;
      _toast('Trip ${newStatus.replaceAll('_', ' ')} successfully');
    } catch (_) {
      if (!mounted) return;
      _toast('Could not update trip. Try again.');
    }
  }

  // ── BUILD ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              Expanded(child: _bookingsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_C.primaryContainer, _C.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.receipt_long_rounded, color: _C.onPrimary, size: 24),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Bookings', style: TextStyle(
                fontFamily: 'Manrope', fontSize: 26,
                fontWeight: FontWeight.w800, color: _C.onSurface,
                letterSpacing: -0.8,
              )),
              SizedBox(height: 2),
              Text('Your ride history', style: TextStyle(
                fontFamily: 'Plus Jakarta Sans', fontSize: 13,
                color: _C.onSurfaceVariant,
              )),
            ],
          ),
        ),
      ]),
    );
  }

  // ── STREAM BUILDER (FIXED — uses user-filtered stream) ─────────────

  Widget _bookingsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _tripsStream,
      builder: (context, snapshot) {
        // Connection error
        if (snapshot.hasError) {
          debugPrint('❌ Stream error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.cloud_off_rounded, size: 48,
                    color: _C.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text('Could not load bookings',
                    style: TextStyle(fontFamily: 'Manrope', fontSize: 18,
                        fontWeight: FontWeight.w700, color: _C.onSurface)),
                const SizedBox(height: 8),
                Text('Check your connection and try again.',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13,
                        color: _C.onSurfaceVariant.withValues(alpha: 0.7))),
              ]),
            ),
          );
        }

        // Loading
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _C.primaryContainer),
          );
        }

        final trips = snapshot.data!;

        // ── DEBUG PRINTS (as requested) ──
        debugPrint('🟢 Trips: ${trips.length}');
        debugPrint('🟢 First Trip Status: ${trips.isNotEmpty ? trips[0]['status'] : 'none'}');

        // Empty
        if (trips.isEmpty) return _emptyState();

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          itemCount: trips.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (_, i) => _bookingCard(trips[i]),
        );
      },
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _C.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: _C.primaryContainer, size: 36),
          ),
          const SizedBox(height: 24),
          const Text('No bookings yet', style: TextStyle(
            fontFamily: 'Manrope', fontSize: 22,
            fontWeight: FontWeight.w800, color: _C.onSurface,
            letterSpacing: -0.5,
          )),
          const SizedBox(height: 8),
          Text(
            'Book your first ride from the Book Ride tab.\nAll your trips will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans', fontSize: 14,
              color: _C.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Booking Card (Premium) ──────────────────────────────────────────

  Widget _bookingCard(Map<String, dynamic> trip) {
    final tripId    = _d(trip['id'], '');
    final status    = _d(trip['status'], 'pending');
    final vehicle   = _d(trip['vehicle_type'], 'Vehicle');
    final pickup    = _d(trip['pickup_location'], 'Pickup not set');
    final dropoff   = _d(trip['dropoff_location'], 'Dropoff not set');
    final driver    = _d(trip['driver_name'], 'Driver pending');
    final phone     = _d(trip['driver_phone'], '');
    final price     = _d(trip['price'], '');
    final createdAt = _fmtDate(trip['created_at']?.toString());
    final startDate = _fmtDate(trip['start_date']?.toString());

    final isActive =
        ['approved', 'assigned', 'in_progress'].contains(status.toLowerCase());
    final isPendingPayment = status.toLowerCase() == 'pending_payment';
    final isPending = status.toLowerCase() == 'pending';
    final isCompleted = status.toLowerCase() == 'completed';
    final isCancelled = status.toLowerCase() == 'cancelled';
    final hasDriver = driver != 'Driver pending';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: isActive
            ? Border.all(
                color: _C.primaryContainer.withValues(alpha: 0.25), width: 1.5)
            : isPendingPayment
                ? Border.all(
                    color: _C.secondary.withValues(alpha: 0.25), width: 1.5)
                : null,
        boxShadow: [
          BoxShadow(
            color: _C.onSurface.withValues(alpha: 0.04),
            blurRadius: 24, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: vehicle + status chip ──
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive || isPendingPayment
                      ? [_C.primaryContainer, _C.primary]
                      : [_C.surfaceHigh, _C.surfaceLow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _vehicleIco(vehicle),
                color: isActive || isPendingPayment ? _C.onPrimary : _C.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle, style: const TextStyle(
                  fontFamily: 'Manrope', fontSize: 16,
                  fontWeight: FontWeight.w800, color: _C.onSurface,
                )),
                const SizedBox(height: 4),
                Text(createdAt, style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 12,
                  color: _C.onSurfaceVariant.withValues(alpha: 0.6),
                )),
              ],
            )),
            GestureDetector(
              onTap: () => _copyId(tripId),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusClr(status).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_statusIco(status), size: 14, color: _statusClr(status)),
                  const SizedBox(width: 5),
                  Text(_statusLabel(status), style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans', fontSize: 11,
                    fontWeight: FontWeight.w700, color: _statusClr(status),
                  )),
                ]),
              ),
            ),
          ]),

          const SizedBox(height: 14),
          Container(height: 1, color: _C.outline.withValues(alpha: 0.15)),
          const SizedBox(height: 14),

          // ── Route dots ──
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: _C.primaryContainer,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              Container(width: 2, height: 24,
                  color: _C.outline.withValues(alpha: 0.3)),
              Icon(Icons.location_on_rounded, size: 14,
                  color: _C.secondary.withValues(alpha: 0.8)),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pickup, style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 13,
                  fontWeight: FontWeight.w600, color: _C.onSurface,
                )),
                const SizedBox(height: 18),
                Text(dropoff, style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 13,
                  fontWeight: FontWeight.w600, color: _C.onSurface,
                )),
              ],
            )),
          ]),

          const SizedBox(height: 14),
          Container(height: 1, color: _C.outline.withValues(alpha: 0.15)),
          const SizedBox(height: 12),

          // ── Driver Info (Premium Card) ──
          if (hasDriver) ...[
            _premiumDriverCard(driver, phone, vehicle, price),
            const SizedBox(height: 12),
          ] else ...[
            // Simple chips for pending state
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip(Icons.person_rounded, driver),
              if (price.isNotEmpty)
                _chip(Icons.currency_rupee_rounded, '₹$price'),
            ]),
            const SizedBox(height: 8),
          ],

          // ── Start date ──
          if (startDate != '—') ...[
            _chip(Icons.schedule_rounded, 'Start: $startDate'),
            const SizedBox(height: 8),
          ],

          // ── Price highlight for pending_payment ──
          if (isPendingPayment && price.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _C.secondary.withValues(alpha: 0.08),
                    _C.secondary.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.secondary.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _C.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.request_quote_rounded,
                      color: _C.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quoted Price', style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans', fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _C.onSurfaceVariant.withValues(alpha: 0.7),
                    )),
                    const SizedBox(height: 2),
                    Text('₹$price', style: const TextStyle(
                      fontFamily: 'Manrope', fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _C.onSurface,
                    )),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Awaiting', style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans', fontSize: 10,
                    fontWeight: FontWeight.w700, color: Color(0xFF92400E),
                  )),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // ── Action Buttons ──

          // Track Live (active trips)
          if (isActive)
            _actionBtn(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TrackingScreen(tripId: tripId))),
              gradient: [_C.primaryContainer, _C.primary],
              icon: Icons.location_on_rounded,
              label: 'Track Live',
            ),

          // Accept / Reject (pending_payment)
          if (isPendingPayment) ...[
            Row(children: [
              Expanded(child: _actionBtn(
                onTap: () => _updateStatus(tripId, 'cancelled'),
                color: _C.surfaceHigh,
                icon: Icons.close_rounded,
                label: 'Reject',
                textColor: _C.onSurfaceVariant.withValues(alpha: 0.8),
              )),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(
                onTap: () => _updateStatus(tripId, 'approved'),
                gradient: [_C.primaryContainer, _C.primary],
                icon: Icons.check_rounded,
                label: 'Accept Quote',
              )),
            ]),
          ],

          // Pending state hint
          if (isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: _C.surfaceLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _C.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Waiting for admin to allot a vehicle & driver…',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans', fontSize: 12,
                    color: _C.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                )),
              ]),
            ),

          // Completed badge
          if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: _C.completed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.completed.withValues(alpha: 0.15)),
              ),
              child: Row(children: [
                const Icon(Icons.verified_rounded, color: _C.completed, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Trip completed successfully',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans', fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.completed.withValues(alpha: 0.9),
                  ),
                )),
              ]),
            ),

          // Cancelled badge
          if (isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: _C.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.error.withValues(alpha: 0.12)),
              ),
              child: Row(children: [
                const Icon(Icons.cancel_rounded, color: _C.error, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'This trip was cancelled',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans', fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.error.withValues(alpha: 0.8),
                  ),
                )),
              ]),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Premium Driver Tracking Card
  // ─────────────────────────────────────────────────────────────────────

  Widget _premiumDriverCard(
      String name, String phone, String vehicle, String price) {
    final hasPhone = phone.isNotEmpty;
    final initials = name
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _C.primaryContainer.withValues(alpha: 0.06),
            _C.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.primaryContainer.withValues(alpha: 0.12)),
      ),
      child: Column(children: [
        // Driver identity row
        Row(children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_C.primaryContainer, _C.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _C.primaryContainer.withValues(alpha: 0.3),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: Text(
              initials.isNotEmpty ? initials : 'DR',
              style: const TextStyle(
                fontFamily: 'Manrope', fontSize: 16,
                fontWeight: FontWeight.w800, color: _C.onPrimary,
              ),
            )),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(
                fontFamily: 'Manrope', fontSize: 15,
                fontWeight: FontWeight.w800, color: _C.onSurface,
              )),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.verified_rounded, size: 13,
                    color: _C.primaryContainer.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text('Verified Driver', style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.primaryContainer.withValues(alpha: 0.7),
                )),
              ]),
            ],
          )),
          if (price.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _C.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _C.onSurface.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text('₹$price', style: const TextStyle(
                fontFamily: 'Manrope', fontSize: 14,
                fontWeight: FontWeight.w800, color: _C.onSurface,
              )),
            ),
        ]),

        const SizedBox(height: 14),

        // Quick-action buttons
        Row(children: [
          // Call Driver
          if (hasPhone)
            Expanded(child: _driverAction(
              icon: Icons.phone_rounded,
              label: 'Call',
              color: _C.primaryContainer,
              onTap: () => _callDriver(phone),
            )),
          if (hasPhone) const SizedBox(width: 8),

          // Copy Phone
          if (hasPhone)
            Expanded(child: _driverAction(
              icon: Icons.copy_rounded,
              label: 'Copy',
              color: _C.inProgress,
              onTap: () {
                Clipboard.setData(ClipboardData(text: phone));
                _toast('Driver phone copied');
              },
            )),
          if (hasPhone) const SizedBox(width: 8),

          // WhatsApp
          if (hasPhone)
            Expanded(child: _driverAction(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () async {
                final uri = Uri.parse(
                    'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            )),

          // If no phone, show a single info chip
          if (!hasPhone)
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _C.surfaceLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.phone_disabled_rounded, size: 14,
                    color: _C.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text('Phone not available yet', style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans', fontSize: 11,
                  color: _C.onSurfaceVariant.withValues(alpha: 0.6),
                )),
              ]),
            )),
        ]),
      ]),
    );
  }

  Widget _driverAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontFamily: 'Plus Jakarta Sans', fontSize: 11,
            fontWeight: FontWeight.w700, color: color,
          )),
        ]),
      ),
    );
  }

  // ── Reusable Widgets ────────────────────────────────────────────────

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _C.surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: _C.onSurfaceVariant.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(
          fontFamily: 'Plus Jakarta Sans', fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _C.onSurfaceVariant.withValues(alpha: 0.8),
        )),
      ]),
    );
  }

  Widget _actionBtn({
    required VoidCallback onTap,
    List<Color>? gradient,
    Color? color,
    required IconData icon,
    required String label,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient != null
              ? LinearGradient(
                  colors: gradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: gradient == null ? (color ?? _C.surfaceHigh) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: textColor ?? _C.onPrimary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            fontFamily: 'Plus Jakarta Sans', fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textColor ?? _C.onPrimary,
          )),
        ]),
      ),
    );
  }
}
