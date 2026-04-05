import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Rental Policy'),
              const SizedBox(height: 16),
              _buildRule(
                1,
                'Distance and Time Calculation',
                'Distance (kilometers) and time will be calculated from garage-to-garage (shed to shed).',
              ),
              _buildRule(
                2,
                'Passenger Capacity',
                'Passenger capacity must not exceed vehicle limits:\n• Car: Maximum 5 passengers\n• Van: Maximum 12 passengers',
              ),
              _buildRule(
                3,
                'Outstation Trips',
                'For outstation trips, a minimum of 300 km per day will be charged, regardless of actual usage.',
              ),
              _buildRule(
                4,
                'Local Trips',
                'For local trips, usage exceeding 7 hours will be charged as a 10-hour package.',
              ),
              _buildRule(
                5,
                'Overnight Allowance',
                'For outstation trips, travel after 12:00 AM will incur an additional driver allowance (night charge).',
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  '© 2026 Chennai City Rides',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Color(0xFF191C1D),
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildRule(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF166534),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191C1D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    color: const Color(0xFF404940).withValues(alpha: 0.8),
                    height: 1.5,
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
