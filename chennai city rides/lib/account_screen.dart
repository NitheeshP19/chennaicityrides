import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Premium green design system
class _AC {
  static const Color primary = Color(0xFF004C22);
  static const Color primaryContainer = Color(0xFF166534);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF404940);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE8ECE8);
  static const Color danger = Color(0xFFDC2626);
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
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

  String get _userName {
    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    return (metadata?['full_name'] ?? metadata?['name'] ?? 'Rider')
        .toString()
        .trim();
  }

  String get _userEmail {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.email ?? 'rider@example.com';
  }

  String get _userInitial {
    if (_userName.isEmpty) return 'R';
    return _userName.substring(0, 1).toUpperCase();
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _AC.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: _AC.danger,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sign Out?',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _AC.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You will need to sign in again to access your bookings and track rides.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: _AC.onSurfaceVariant.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _AC.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _AC.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _AC.danger,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Center(
                          child: Text(
                            'Sign Out',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not sign out. Please try again.'),
            backgroundColor: _AC.danger,
          ),
        );
      }
    }
  }

  void _showAboutApp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PremiumBottomSheet(
        icon: Icons.directions_bus_rounded,
        title: 'About Chennai City Rides',
        children: [
          _aboutItem(
            Icons.verified_rounded,
            'Premium Transit Service',
            'Chennai City Rides is your trusted partner for premium group transit across Tamil Nadu. From airport transfers to multi-day tours, we offer a wide fleet of AC and Non-AC vehicles.',
          ),
          _aboutItem(
            Icons.local_shipping_rounded,
            'Expansive Fleet',
            'Choose from 11+ vehicle categories — 4-seater cars to 54-seater luxury AC buses. Every vehicle is maintained to the highest standards.',
          ),
          _aboutItem(
            Icons.security_rounded,
            'Safe & Reliable',
            'All our drivers are verified professionals with years of experience. Real-time GPS tracking ensures complete transparency.',
          ),
          _aboutItem(
            Icons.star_rounded,
            'Version',
            'Chennai City Rides v1.0.0\nBuilt with ❤ in Chennai',
          ),
        ],
      ),
    );
  }

  void _showCustomerHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PremiumBottomSheet(
        icon: Icons.support_agent_rounded,
        title: 'Customer Support',
        children: [
          _helpTile(
            Icons.call_rounded,
            'Call Us',
            'Available 24/7 for your queries',
            () => _launchUrl('tel:+919876543210'),
          ),
          _helpTile(
            Icons.chat_rounded,
            'WhatsApp Support',
            'Quick responses via WhatsApp',
            () => _launchUrl('https://wa.me/919876543210'),
          ),
          _helpTile(
            Icons.email_rounded,
            'Email Support',
            'support@chennaicityrides.com',
            () => _launchUrl('mailto:support@chennaicityrides.com'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _AC.primaryContainer.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: _AC.primaryContainer,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Our support team typically responds within 30 minutes during business hours.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: _AC.onSurfaceVariant,
                      height: 1.4,
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

  void _showHowItWorks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PremiumBottomSheet(
        icon: Icons.auto_awesome_rounded,
        title: 'How It Works',
        children: [
          _stepItem('1', 'Book Your Ride',
              'Select your pickup, drop-off, dates, and vehicle type through our easy booking form.'),
          _stepItem('2', 'Get a Quote',
              'Our admin team reviews your request and sends you a competitive price quotation.'),
          _stepItem('3', 'Confirm & Pay',
              'Accept the quote, make the payment, and your ride is confirmed instantly.'),
          _stepItem('4', 'Track in Real-Time',
              'On the day of travel, track your driver\'s live location right from the app.'),
        ],
      ),
    );
  }

  void _showSafetyFeatures() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PremiumBottomSheet(
        icon: Icons.shield_rounded,
        title: 'Safety Features',
        children: [
          _aboutItem(
            Icons.gps_fixed_rounded,
            'Live GPS Tracking',
            'Track your ride in real-time. Share your live location with family and friends for added safety.',
          ),
          _aboutItem(
            Icons.verified_user_rounded,
            'Verified Drivers',
            'All drivers undergo thorough background checks and are experienced professionals.',
          ),
          _aboutItem(
            Icons.car_repair_rounded,
            'Vehicle Inspections',
            'Every vehicle goes through regular safety inspections and maintenance checks.',
          ),
          _aboutItem(
            Icons.emergency_rounded,
            'Emergency Support',
            '24/7 emergency assistance available. Our support team is always a call away.',
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently handle if URL can't be opened
    }
  }

  Widget _aboutItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _AC.primaryContainer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: _AC.primaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _AC.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: _AC.onSurfaceVariant.withValues(alpha: 0.7),
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

  Widget _helpTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _AC.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _AC.divider.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AC.primaryContainer, _AC.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: _AC.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _AC.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: _AC.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _AC.onSurfaceVariant.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_AC.primaryContainer, _AC.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _AC.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _AC.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: _AC.onSurfaceVariant.withValues(alpha: 0.7),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AC.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildProfileHeader()),
              SliverToBoxAdapter(child: _buildQuickActions()),
              SliverToBoxAdapter(child: _buildMenuSection()),
              SliverToBoxAdapter(child: _buildSignOutButton()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Account',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _AC.onSurface,
                  letterSpacing: -1,
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _AC.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _AC.onSurface.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_outlined, size: 22),
                  color: _AC.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Profile card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF166534), Color(0xFF004C22)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _AC.primaryContainer.withValues(alpha: 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _userInitial,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
                        _userName,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '⭐ Premium Rider',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          _buildQuickActionCard(
            Icons.auto_awesome_rounded,
            'How It\nWorks',
            _showHowItWorks,
          ),
          const SizedBox(width: 12),
          _buildQuickActionCard(
            Icons.shield_rounded,
            'Safety\nFeatures',
            _showSafetyFeatures,
          ),
          const SizedBox(width: 12),
          _buildQuickActionCard(
            Icons.support_agent_rounded,
            'Get\nHelp',
            _showCustomerHelp,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _AC.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _AC.onSurface.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _AC.primaryContainer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _AC.primaryContainer, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _AC.onSurface,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _AC.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _AC.onSurface.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildMenuItem(
              Icons.info_outline_rounded,
              'About Chennai City Rides',
              'Learn about our service',
              onTap: _showAboutApp,
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              Icons.support_agent_rounded,
              'Customer Support',
              'Call, WhatsApp, or email us',
              onTap: _showCustomerHelp,
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              Icons.auto_awesome_rounded,
              'How It Works',
              'Step-by-step guide',
              onTap: _showHowItWorks,
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              Icons.shield_outlined,
              'Safety Features',
              'Your safety is our priority',
              onTap: _showSafetyFeatures,
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              Icons.description_outlined,
              'Terms & Conditions',
              'Service agreement',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _SimpleTextScreen(
                      title: 'Terms & Conditions',
                      content: _termsText,
                    ),
                  ),
                );
              },
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'How we handle your data',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const _SimpleTextScreen(
                      title: 'Privacy Policy',
                      content: _privacyText,
                    ),
                  ),
                );
              },
            ),
            _buildMenuDivider(),
            _buildMenuItem(
              Icons.share_outlined,
              'Share App',
              'Tell your friends about us',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('App sharing coming soon!'),
                    backgroundColor: _AC.primaryContainer,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _AC.primaryContainer.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: _AC.primaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _AC.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: _AC.onSurfaceVariant.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _AC.onSurfaceVariant.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: _AC.divider.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: GestureDetector(
        onTap: _signOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _AC.danger.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: _AC.danger.withValues(alpha: 0.15),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 20, color: _AC.danger),
              SizedBox(width: 10),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _AC.danger,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Premium Bottom Sheet ────────────────────────────────────
class _PremiumBottomSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _PremiumBottomSheet({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _AC.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _AC.onSurfaceVariant.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_AC.primaryContainer, _AC.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: _AC.onPrimary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _AC.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _AC.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: children,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Simple Text Screen for Terms/Privacy ────────────────────
class _SimpleTextScreen extends StatelessWidget {
  final String title;
  final String content;

  const _SimpleTextScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AC.surface,
      appBar: AppBar(
        backgroundColor: _AC.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          color: _AC.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _AC.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          content,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            color: _AC.onSurfaceVariant.withValues(alpha: 0.8),
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

const String _termsText = '''
Terms and Conditions of Chennai City Rides

Last Updated: April 2026

1. ACCEPTANCE OF TERMS
By using the Chennai City Rides mobile application, you agree to these Terms and Conditions.

2. SERVICE DESCRIPTION
Chennai City Rides provides vehicle booking services for group transit across Tamil Nadu. We connect customers with verified drivers and a fleet of vehicles ranging from sedans to buses.

3. BOOKING & CANCELLATION
• All bookings are subject to availability.
• Cancellations made 24 hours before the trip are eligible for a full refund.
• Late cancellations may incur a cancellation fee.

4. PAYMENT
• Prices are quoted per trip based on vehicle type, distance, and duration.
• Payment must be completed before the trip begins.
• We accept UPI, bank transfer, and cash payments.

5. LIABILITY
• Chennai City Rides acts as a platform connecting riders with drivers.
• We are not liable for delays caused by traffic, weather, or other unforeseen circumstances.
• Maximum liability is limited to the trip fare paid.

6. CONTACT
For any concerns, contact support@chennaicityrides.com.
''';

const String _privacyText = '''
Privacy Policy of Chennai City Rides

Last Updated: April 2026

1. INFORMATION WE COLLECT
• Name and email through Google Sign-In
• Phone number and contact details for trip coordination
• Pickup and dropoff locations
• Trip history

2. HOW WE USE YOUR DATA
• To process and manage your bookings
• To connect you with drivers
• To provide real-time tracking
• To send trip-related notifications

3. DATA SHARING
• Your contact details are shared only with assigned drivers
• We do not sell your personal data to third parties
• Location data is used solely for trip tracking

4. DATA SECURITY
• All data is encrypted in transit and at rest
• We use Supabase for secure data storage
• Authentication is handled through Google OAuth

5. YOUR RIGHTS
• You can request deletion of your account and data
• You can opt out of marketing communications

6. CONTACT
For privacy concerns, contact support@chennaicityrides.com.
''';
