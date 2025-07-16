import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isChecked = false;
  bool _isNavigating = false;

  void _onCheckboxChanged(bool? value) {
    setState(() {
      _isChecked = value ?? false;
    });
  }

  void _navigateToRegister() async {
    if (_isChecked && !_isNavigating) {
      setState(() => _isNavigating = true);
      await Navigator.pushNamed(context, '/detailsEntry');
      setState(() => _isNavigating = false);
    } else if (!_isChecked) {
      _showAgreementAlert();
    }
  }

  void _navigateToLogin() async {
    if (_isChecked && !_isNavigating) {
      setState(() => _isNavigating = true);
      await Navigator.pushNamed(context, '/login');
      setState(() => _isNavigating = false);
    } else if (!_isChecked) {
      _showAgreementAlert();
    }
  }

  void _showAgreementAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please agree to the terms before proceeding.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getIndigoColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.indigo[300]! : Colors.indigo;
  }

  Color _getIndigoShade700(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.indigo[400]! : Colors.indigo.shade700;
  }

  Color _getCardBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.grey[900]! : Colors.white;
  }

  Color _getFeatureTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.white70 : Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final indigoColor = _getIndigoColor(context);
    final indigoShade700 = _getIndigoShade700(context);
    final cardBgColor = _getCardBackground(context);
    final featureTextColor = _getFeatureTextColor(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, color: indigoShade700, size: 28),
            const SizedBox(width: 10),
            Text(
              'Simatix',
              style: TextStyle(
                color: indigoShade700,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontFamily: 'Segoe UI',
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Colors.indigo.shade900, Colors.black87]
                : [Colors.indigo.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Empowering students through smart, centralized access to academic,\nadministrative, and campus essentials — anytime, anywhere.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: indigoShade700,
                        letterSpacing: 0.6,
                        height: 1.4,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          )
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Why Simatix?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: indigoShade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint(Icons.hub, 'One-stop hub for all campus utilities', featureTextColor),
                    _buildBulletPoint(Icons.lock_open, 'Streamlined access to official student portals', featureTextColor),
                    _buildBulletPoint(Icons.verified_user, 'Built specifically for Saveetha students', featureTextColor),
                    _buildBulletPoint(Icons.speed, 'Simple, fast, and secure user experience', featureTextColor),
                    _buildBulletPoint(Icons.update, 'Continuously evolving based on your feedback', featureTextColor),
                    const SizedBox(height: 24),
                    Text(
                      'Core Features:',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: indigoShade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint(Icons.dashboard_customize, 'ARMS Portal: View marks, attendance & timetables in one tap', featureTextColor),
                    _buildBulletPoint(Icons.restaurant_menu, 'Food Portal: Access the canteen menu and order your food', featureTextColor),
                    _buildBulletPoint(Icons.reviews, 'Canteen Food Reviews: View and share reviews of the canteen food', featureTextColor),
                    _buildBulletPoint(Icons.calculate, 'CGPA Calculator: Predict and track your performance accurately', featureTextColor),
                    _buildBulletPoint(Icons.contact_phone, 'Faculty Directory: Instantly connect with faculty and departments', featureTextColor),
                    _buildBulletPoint(Icons.picture_as_pdf, 'PDF Resource Hub: Quickly access and download course material', featureTextColor),
                    _buildBulletPoint(Icons.access_time, 'Attendance Calculator: Know your attendance lifeline', featureTextColor),
                    _buildBulletPoint(Icons.account_circle, 'Profile & Info Management: Manage student details securely', featureTextColor),
                    _buildBulletPoint(Icons.menu_book, 'Department Subjects: Browse your course curriculum by branch', featureTextColor),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildFeatureCard(
                '⚠️ Important Guidelines',
                [
                  {
                    'icon': Icons.verified_user,
                    'text': 'Use the app responsibly; respect privacy and data security.'
                  },
                  {
                    'icon': Icons.school,
                    'text': 'Exclusive access for Saveetha Institute students only.'
                  },
                  {
                    'icon': Icons.lock,
                    'text': 'All data is securely stored and confidential.'
                  },
                ],
                indigoShade700,
                cardBgColor,
                featureTextColor,
              ),
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isChecked,
                    onChanged: _onCheckboxChanged,
                    activeColor: indigoShade700,
                    checkColor: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      'I am a student of Saveetha Institute of Medical and Technical Sciences, and I agree to use the app responsibly.',
                      style: TextStyle(
                        fontSize: 16,
                        color: featureTextColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isChecked ? _navigateToRegister : null,
                      icon: const Icon(Icons.person_add),
                      label: const Text(
                        'Register (New User)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: indigoShade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isChecked ? 8 : 0,
                        shadowColor: indigoShade700.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isChecked ? _navigateToLogin : null,
                      icon: const Icon(Icons.login),
                      label: const Text(
                        'Login',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: indigoShade700.withOpacity(0.85),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isChecked ? 8 : 0,
                        shadowColor: indigoShade700.withOpacity(0.6),
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
  }

  Widget _buildBulletPoint(IconData icon, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, List<Map<String, dynamic>> features, Color titleColor,
      Color cardBgColor, Color featureTextColor) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: cardBgColor,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: titleColor,
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 20),
            for (var feature in features) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(feature['icon'], color: titleColor, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      feature['text'],
                      style: TextStyle(
                        fontSize: 17,
                        color: featureTextColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}
