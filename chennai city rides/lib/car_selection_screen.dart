import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppColors {
  static const Color primary = Color(0xFF004C22);
  static const Color primaryContainer = Color(0xFF166534);
  static const Color secondary = Color(0xFF9D4300);
  static const Color secondaryContainer = Color(0xFFFD761A);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF404940);
  static const Color outlineVariant = Color(0xFFBFC9BD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFA6F4B5);
}

class VehicleOption {
  final String name;
  final String description;
  final IconData icon;
  final int capacity;

  const VehicleOption({
    required this.name,
    required this.description,
    required this.icon,
    required this.capacity,
  });
}

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({super.key});

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen>
    with TickerProviderStateMixin {
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  int _selectedVehicleIndex = 0;
  int _passengerCount = 2;
  bool _isBooking = false;

  late DateTime _startDate;
  late DateTime _endDate;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<VehicleOption> vehicles = const [
    VehicleOption(
      name: 'Car',
      description: 'Premium comfort for 4',
      icon: Icons.directions_car_rounded,
      capacity: 4,
    ),
    VehicleOption(
      name: 'SUV',
      description: 'Spacious travel for 6',
      icon: Icons.local_taxi_rounded,
      capacity: 6,
    ),
    VehicleOption(
      name: '12-Seater',
      description: 'Executive group van',
      icon: Icons.airport_shuttle_rounded,
      capacity: 12,
    ),
    VehicleOption(
      name: '24-Seater',
      description: 'Corporate shuttle',
      icon: Icons.directions_bus_rounded,
      capacity: 24,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().add(const Duration(hours: 1));
    _endDate = _startDate.add(const Duration(hours: 4));

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
    _pickupController.dispose();
    _dropoffController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } on AuthException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Could not sign out right now.', isError: true);
    }
  }

  String get _userInitial {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final displayName =
        (metadata?['full_name'] ?? metadata?['name'] ?? user?.email ?? 'Rider')
            .toString()
            .trim();

    if (displayName.isEmpty) {
      return 'R';
    }

    return displayName.substring(0, 1).toUpperCase();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, $hour:$minute $period';
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart ? DateTime.now() : _startDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;

    final pickedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!isStart && !pickedDateTime.isAfter(_startDate)) {
      _showSnackBar('End time must be after the start time.', isError: true);
      return;
    }

    setState(() {
      if (isStart) {
        _startDate = pickedDateTime;
        if (!_endDate.isAfter(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 4));
        }
      } else {
        _endDate = pickedDateTime;
      }
    });
  }

  void _showContactSheet() {
    final pickup = _pickupController.text.trim();
    final dropoff = _dropoffController.text.trim();

    if (pickup.isEmpty || dropoff.isEmpty) {
      _showSnackBar('Enter both pickup and dropoff locations.', isError: true);
      return;
    }

    if (!_endDate.isAfter(_startDate)) {
      _showSnackBar('End time must be after the start time.', isError: true);
      return;
    }

    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ContactBottomSheet(
          nameController: nameController,
          phoneController: phoneController,
          isBooking: _isBooking,
          onSubmit: () async {
            final name = nameController.text.trim();
            final phone = phoneController.text.trim();

            if (name.isEmpty || phone.isEmpty) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(
                  content: Text('Please enter both name and phone number.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            if (phone.length < 10) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid phone number.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            Navigator.of(sheetContext).pop();
            await _submitTrip(name, phone);
          },
        );
      },
    );
  }

  Future<void> _submitTrip(String customerName, String customerPhone) async {
    if (_isBooking) return;

    setState(() => _isBooking = true);

    final pickup = _pickupController.text.trim();
    final dropoff = _dropoffController.text.trim();
    final selectedVehicle = vehicles[_selectedVehicleIndex];

    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      await Supabase.instance.client
          .from('trip_requests')
          .insert({
            'user_id': userId,
            'pickup_location': pickup,
            'dropoff_location': dropoff,
            'vehicle_type': selectedVehicle.name,
            'start_date': _startDate.toIso8601String(),
            'passenger_count': _passengerCount,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'status': 'New',
          })
          .select('id')
          .single();

      if (!mounted) return;

      // Clear form
      _pickupController.clear();
      _dropoffController.clear();
      setState(() {
        _passengerCount = 2;
        _selectedVehicleIndex = 0;
        _startDate = DateTime.now().add(const Duration(hours: 1));
        _endDate = _startDate.add(const Duration(hours: 4));
      });

      _showSuccessDialog();
    } on AuthException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message, isError: true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        'Could not create the trip request. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.onPrimary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Request Sent!',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your trip request has been sent to the admin. '
                'You will receive a quotation and driver details shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryContainer,
                        AppColors.primary,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Center(
                    child: Text(
                      'Got it',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = vehicles[_selectedVehicleIndex];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildTripForm()),
              SliverToBoxAdapter(child: _buildDateSection()),
              SliverToBoxAdapter(child: _buildVehicleSelection()),
              SliverToBoxAdapter(child: _buildFooter(selectedVehicle)),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _signOut,
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  color: AppColors.onSurface,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chennai City Rides',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryContainer,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryContainer, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _userInitial,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Plan your\nride request',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -1.5,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a real trip request for the admin team and driver tracker.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          _buildLocationField(
            label: 'Pickup location',
            hint: 'Airport, office, hotel, or landmark',
            controller: _pickupController,
            icon: Icons.my_location_rounded,
          ),
          const SizedBox(height: 16),
          _buildLocationField(
            label: 'Dropoff location',
            hint: 'Where should we take you?',
            controller: _dropoffController,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 16),
          _buildPassengerSelector(),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildDateCard(
              label: 'Start Date',
              value: _formatDate(_startDate),
              onTap: () => _pickDateTime(isStart: true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDateCard(
              label: 'End Date',
              value: _formatDate(_endDate),
              onTap: () => _pickDateTime(isStart: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How many are traveling?',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_passengerCount passengers',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildCounterButton(Icons.remove_rounded, () {
                if (_passengerCount > 1) {
                  setState(() => _passengerCount--);
                }
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_passengerCount',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _buildCounterButton(Icons.add_rounded, () {
                if (_passengerCount <
                    vehicles[_selectedVehicleIndex].capacity) {
                  setState(() => _passengerCount++);
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.primaryContainer),
      ),
    );
  }

  Widget _buildVehicleSelection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select vehicle',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(vehicles.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < vehicles.length - 1 ? 14 : 0,
              ),
              child: _buildVehicleCard(index),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(int index) {
    final vehicle = vehicles[index];
    final isSelected = _selectedVehicleIndex == index;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedVehicleIndex = index;
        if (_passengerCount > vehicle.capacity) {
          _passengerCount = vehicle.capacity;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryContainer.withValues(alpha: 0.3)
                : AppColors.outlineVariant.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.primaryContainer, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                vehicle.icon,
                color: isSelected
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.description,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer.withValues(alpha: 0.1)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${vehicle.capacity} seats',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(VehicleOption selectedVehicle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isBooking ? null : _showContactSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondaryContainer, AppColors.secondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(9999),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: _isBooking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.onSecondary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Create trip request',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${selectedVehicle.name} - ${selectedVehicle.capacity} seats - $_passengerCount passenger(s)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryContainer,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Bottom Sheet Widget ─────────────────────────────
class _ContactBottomSheet extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool isBooking;
  final VoidCallback onSubmit;

  const _ContactBottomSheet({
    required this.nameController,
    required this.phoneController,
    required this.isBooking,
    required this.onSubmit,
  });

  @override
  State<_ContactBottomSheet> createState() => _ContactBottomSheetState();
}

class _ContactBottomSheetState extends State<_ContactBottomSheet> {
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_updateSubmitState);
    widget.phoneController.addListener(_updateSubmitState);
  }

  void _updateSubmitState() {
    final ready = widget.nameController.text.trim().isNotEmpty &&
        widget.phoneController.text.trim().length >= 10;
    if (ready != _canSubmit) {
      setState(() => _canSubmit = ready);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryContainer, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Details',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'We\'ll share this with the driver',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name field
            _buildField(
              controller: widget.nameController,
              label: 'Full Name',
              hint: 'Enter your name',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),

            // Phone field
            _buildField(
              controller: widget.phoneController,
              label: 'Phone Number',
              hint: '10-digit mobile number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              maxLength: 15,
            ),
            const SizedBox(height: 24),

            // Submit button
            GestureDetector(
              onTap: _canSubmit && !widget.isBooking ? widget.onSubmit : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _canSubmit
                      ? const LinearGradient(
                          colors: [
                            AppColors.secondaryContainer,
                            AppColors.secondary,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: _canSubmit ? null : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: _canSubmit
                      ? [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    _canSubmit ? 'Confirm & Create Trip' : 'Enter name & phone to continue',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _canSubmit
                          ? AppColors.onSecondary
                          : AppColors.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    int? maxLength,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
