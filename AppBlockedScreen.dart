import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppBlockedScreen extends StatelessWidget {
  const AppBlockedScreen({super.key});

  // Launch email to support
  Future<void> _launchEmailSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'simatix.developer@gmail.com',
      queryParameters: {
        'subject': 'App Access Disabled - Support Request',
        'body': 'Dear Support Team,\n\nI am experiencing issues accessing the Simatix app. Please assist.\n\nThank you.',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      // Could show a snackbar or alert if cannot open email
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                color: Colors.red.shade700,
                size: 90,
              ),
              const SizedBox(height: 24),
              const Text(
                'Access Temporarily Disabled',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We apologize for the inconvenience. The app is currently unavailable. '
                    'Please try again later or contact customer support for assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Manual retry reloads app root
                  Navigator.pushReplacementNamed(context, '/');
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _launchEmailSupport,
                icon: const Icon(Icons.support_agent, color: Colors.red),
                label: const Text(
                  'Contact Customer Support',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade700),
                  minimumSize: const Size(double.infinity, 48),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
