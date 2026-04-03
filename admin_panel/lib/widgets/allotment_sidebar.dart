import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../screens/tracking_view.dart';
import '../services/supabase_service.dart';

class AllotmentSidebar extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final VoidCallback onClosed;

  const AllotmentSidebar({
    super.key,
    required this.tripData,
    required this.onClosed,
  });

  @override
  State<AllotmentSidebar> createState() => _AllotmentSidebarState();
}

class _AllotmentSidebarState extends State<AllotmentSidebar> {
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _quotedPriceController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant AllotmentSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tripData['id'] != widget.tripData['id']) {
      _syncControllers();
    }
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _quotedPriceController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _driverNameController.text =
        widget.tripData['driver_name']?.toString() ?? '';
    _driverPhoneController.text =
        widget.tripData['driver_phone']?.toString() ?? '';
    _quotedPriceController.text =
        widget.tripData['quoted_price']?.toString() ?? '';
  }

  String _displayValue(dynamic value, String fallback) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') {
      return fallback;
    }
    return text;
  }

  String get _trackerLink {
    const configuredBaseUrl = String.fromEnvironment('DRIVER_TRACKER_URL');
    final tripId = widget.tripData['id'].toString();

    if (configuredBaseUrl.isNotEmpty) {
      return Uri.parse(
        configuredBaseUrl,
      ).replace(queryParameters: {'trip_id': tripId}).toString();
    }

    final current = Uri.base;
    final inferredPort = current.port == 8081 ? 8080 : current.port;

    return Uri(
      scheme: current.scheme,
      host: current.host,
      port: inferredPort == 80 || inferredPort == 443 ? null : inferredPort,
      queryParameters: {'trip_id': tripId},
    ).toString();
  }

  Future<void> _allotVehicle() async {
    final driverName = _driverNameController.text.trim();
    final driverPhone = _driverPhoneController.text.trim();
    final quotedPrice = double.tryParse(_quotedPriceController.text.trim());

    if (driverName.isEmpty || driverPhone.isEmpty || quotedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter driver name, phone number, and a valid quoted price.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await supabaseService.allotTrip(
        tripId: widget.tripData['id'].toString(),
        driverName: driverName,
        driverPhone: driverPhone,
        quotedPrice: quotedPrice,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip allotted successfully.'),
          backgroundColor: EmeraldOrbitTheme.primaryGreen,
        ),
      );
      widget.onClosed();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to allot the trip right now.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _displayValue(widget.tripData['status'], 'New');
    final isAllotted = status == 'Allotted';

    return Container(
      width: 400,
      color: EmeraldOrbitTheme.surfaceWhite,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAllotted ? 'Trip Details' : 'Allot Vehicle',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClosed,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildInfoRow(
                  'Pickup',
                  _displayValue(widget.tripData['pickup_location'], 'N/A'),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Dropoff',
                  _displayValue(widget.tripData['dropoff_location'], 'N/A'),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Vehicle',
                  _displayValue(widget.tripData['vehicle_type'], 'N/A'),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Start Date',
                  _displayValue(widget.tripData['start_date'], 'N/A'),
                ),
                const Divider(height: 48),
                Text(
                  'Driver Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _driverNameController,
                  enabled: !isAllotted,
                  decoration: const InputDecoration(labelText: 'Driver Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _driverPhoneController,
                  enabled: !isAllotted,
                  decoration: const InputDecoration(labelText: 'Driver Phone'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quotedPriceController,
                  enabled: !isAllotted,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quoted Price (INR)',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: isAllotted ? _buildTrackerActions() : _buildAllotButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerActions() {
    return Column(
      children: [
        Text(
          'Driver Tracking Link',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: EmeraldOrbitTheme.primaryGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: EmeraldOrbitTheme.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.link,
                color: EmeraldOrbitTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _trackerLink,
                  style: const TextStyle(
                    fontSize: 12,
                    color: EmeraldOrbitTheme.primaryGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  size: 18,
                  color: EmeraldOrbitTheme.primaryGreen,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _trackerLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tracker link copied!')),
                  );
                },
                tooltip: 'Copy Tracking Link',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: EmeraldOrbitTheme.premiumOrange,
            ),
            icon: const Icon(Icons.map),
            label: const Text('Admin Live Monitor'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TrackingView(tripId: widget.tripData['id'].toString()),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAllotButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _allotVehicle,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Confirm Allotment'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
