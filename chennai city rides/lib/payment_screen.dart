import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tracking_screen.dart';

class _Colors {
  static const primary = Color(0xFF004C22);
  static const primaryContainer = Color(0xFF166534);
  static const secondary = Color(0xFF9D4300);
  static const secondaryContainer = Color(0xFFFD761A);
  static const surface = Color(0xFFF8F9FA);
  static const surfaceContainerLow = Color(0xFFF3F4F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerHigh = Color(0xFFE7E8E9);
  static const onSurface = Color(0xFF191C1D);
  static const onSurfaceVariant = Color(0xFF404940);
  static const outlineVariant = Color(0xFFBFC9BD);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const primaryFixed = Color(0xFFA6F4B5);
}

class PaymentScreen extends StatefulWidget {
  final String vehicleName;
  final String driverName;
  final double totalAmount;
  final String tripId;

  const PaymentScreen({
    super.key,
    this.vehicleName = 'Executive Ride',
    this.driverName = '',
    this.totalAmount = 4999.0,
    required this.tripId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  bool _receiptAttached = false;
  bool _paymentVerified = false;
  int _selectedPaymentMethod = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
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

  bool get _canVerify {
    if (_selectedPaymentMethod == 1) {
      return true;
    }
    if (_selectedPaymentMethod == 2) {
      return false;
    }
    return _receiptAttached;
  }

  String get _statusText {
    return widget.driverName.trim().isEmpty
        ? 'Awaiting admin allotment'
        : 'Driver allotted';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _Colors.primaryContainer,
      ),
    );
  }

  void _copyUpiId() {
    Clipboard.setData(const ClipboardData(text: 'chennaicityrides@ybl'));
    _showSnackBar('UPI ID copied.');
  }

  void _attachReceipt() {
    setState(() => _receiptAttached = true);
  }

  void _verifyPayment() {
    if (!_canVerify) return;
    setState(() => _paymentVerified = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildTopBar()),
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildTripCard()),
                    SliverToBoxAdapter(child: _buildPaymentMethods()),
                    SliverToBoxAdapter(child: _buildPaymentInfo()),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          const Text(
            'Payment',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _Colors.onSurface,
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _Colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: _Colors.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _Colors.primaryFixed.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusText,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _Colors.primaryContainer,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Finish payment and start tracking.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _Colors.onSurface,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your request has been created in the admin panel. Once the driver opens the tracker link, live GPS will appear automatically.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: _Colors.onSurfaceVariant.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _Colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _Colors.onSurface.withValues(alpha: 0.04),
              blurRadius: 32,
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_Colors.primaryContainer, _Colors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.airport_shuttle_rounded,
                    color: _Colors.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vehicleName,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _Colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trip ID: ${widget.tripId}',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: _Colors.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              height: 1,
              color: _Colors.outlineVariant.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat(
                  'Amount',
                  'INR ${widget.totalAmount.toStringAsFixed(0)}',
                ),
                _buildStat('Status', _statusText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _Colors.onSurfaceVariant.withValues(alpha: 0.6),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _Colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment method',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _Colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMethodCard(0, Icons.qr_code_rounded, 'UPI'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMethodCard(1, Icons.payments_outlined, 'Cash'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMethodCard(2, Icons.credit_card_rounded, 'Card'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(int index, IconData icon, String label) {
    final isSelected = _selectedPaymentMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_Colors.primaryContainer, _Colors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : _Colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? _Colors.onPrimary : _Colors.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? _Colors.onPrimary
                    : _Colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    if (_selectedPaymentMethod == 1) {
      return _buildCashInfo();
    }
    if (_selectedPaymentMethod == 2) {
      return _buildCardInfo();
    }
    return _buildUpiInfo();
  }

  Widget _buildUpiInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _Colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _Colors.onSurface.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UPI instructions',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _Colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pay using your UPI app, then attach the receipt before confirming.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: _Colors.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _Colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    color: _Colors.primaryContainer,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'chennaicityrides@ybl',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        color: _Colors.onSurface,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _copyUpiId, child: const Text('Copy')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _attachReceipt,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _receiptAttached
                      ? _Colors.primaryFixed.withValues(alpha: 0.2)
                      : _Colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _receiptAttached
                        ? _Colors.primaryContainer.withValues(alpha: 0.3)
                        : _Colors.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _receiptAttached
                          ? Icons.check_circle_rounded
                          : Icons.cloud_upload_outlined,
                      color: _receiptAttached
                          ? _Colors.primaryContainer
                          : _Colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _receiptAttached
                          ? 'Receipt attached'
                          : 'Attach receipt screenshot',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        color: _Colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _Colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _Colors.onSurface.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cash payment',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _Colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pay the driver directly. The trip will remain trackable using the same trip ID.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: _Colors.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _Colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _Colors.onSurface.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Card payment',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _Colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Card checkout is not enabled in this zero-cost setup yet. Use UPI or cash for now.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: _Colors.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: _Colors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: _Colors.onSurface.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _paymentVerified
            ? GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TrackingScreen(tripId: widget.tripId),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_Colors.primaryContainer, _Colors.primary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: _Colors.onPrimary,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Payment verified - Track ride',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _Colors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : GestureDetector(
                onTap: _canVerify ? _verifyPayment : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: _canVerify
                        ? const LinearGradient(
                            colors: [
                              _Colors.secondaryContainer,
                              _Colors.secondary,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: _canVerify ? null : _Colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Center(
                    child: Text(
                      _selectedPaymentMethod == 2
                          ? 'Card payments unavailable'
                          : _canVerify
                          ? 'Verify payment'
                          : 'Attach receipt to continue',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _canVerify
                            ? _Colors.onSecondary
                            : _Colors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
