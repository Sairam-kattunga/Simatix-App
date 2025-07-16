import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme_notifier.dart';

class StudentProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const StudentProfileScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Map<String, String?> profileData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentProfile();
  }

  Future<void> _fetchStudentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user logged in.")),
      );
      return;
    }

    final uid = user.uid;
    final email = user.email;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          profileData = {
            'name': data['name'],
            'email': data['email'],
            'regNo': data['regNo'],
            'phone': data['phone'],
            'year': data['year'],
          };
          _loading = false;
        });
      } else {
        if (email == null) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User email not found.")),
          );
          return;
        }

        final querySnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          setState(() {
            profileData = {
              'name': data['name'],
              'email': data['email'],
              'regNo': data['regNo'],
              'phone': data['phone'],
              'year': data['year'],
            };
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student profile not found.")),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDark = themeNotifier.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDark ? Colors.tealAccent[100] : Colors.indigo.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.tealAccent[200] : Colors.indigo),
        actions: [
          Row(
            children: [
              Icon(
                isDark ? Icons.nightlight_round : Icons.wb_sunny,
                color: isDark ? Colors.tealAccent[200] : Colors.orange[600],
                size: 26,
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => themeNotifier.toggleTheme(),
                child: Text(
                  isDark ? "Dark Mode" : "Light Mode",
                  style: TextStyle(
                    color: isDark ? Colors.tealAccent[100] : Colors.indigo.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      backgroundColor: isDark ? const Color(0xFF121A1A) : Colors.blue.shade50,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF004D40) : Colors.indigo.shade300,
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.tealAccent.withOpacity(0.4) : Colors.indigo.shade100,
                    offset: const Offset(0, 5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.person, size: 110, color: Colors.white),
            ),
          ),
          const SizedBox(height: 28),

          // Profile Info Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            shadowColor: isDark ? Colors.tealAccent.withOpacity(0.4) : Colors.indigo.shade100,
            color: isDark ? const Color(0xFF004D40) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  _buildInfoTile("Name", profileData['name'], isDark),
                  const Divider(height: 32, thickness: 1.1, color: Colors.tealAccent),
                  _buildInfoTile("Email", profileData['email'], isDark),
                  const Divider(height: 32, thickness: 1.1, color: Colors.tealAccent),
                  _buildInfoTile("Reg. Number", profileData['regNo'], isDark),
                  const Divider(height: 32, thickness: 1.1, color: Colors.tealAccent),
                  _buildInfoTile("Phone", profileData['phone'], isDark),
                  const Divider(height: 32, thickness: 1.1, color: Colors.tealAccent),
                  _buildInfoTile("Year", profileData['year'], isDark),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // About the App Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 7,
            color: isDark ? const Color(0xFF00695C) : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "About This App",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.tealAccent[100] : Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Simatix is your comprehensive student portal, designed "
                        "to streamline academic activities and campus communication. "
                        "Access your profile, receive real-time notifications, "
                        "manage course materials, and connect with faculty effortlessly.\n\n"
                        "Built with user experience and security in mind, "
                        "this app aims to foster a productive and connected college environment.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.tealAccent[100]?.withOpacity(0.9) : Colors.indigo.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Customer Support Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 7,
            color: isDark ? const Color(0xFF00695C) : Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Customer Support",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.tealAccent[100] : Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'simatix.developer@gmail.com',
                        queryParameters: {
                          'subject': 'Support Request - CollegeConnect App'
                        },
                      );
                      if (await canLaunchUrl(emailLaunchUri)) {
                        await launchUrl(emailLaunchUri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Could not launch email client.")),
                        );
                      }
                    },
                    child: Text(
                      'simatix.developer@gmail.com',
                      style: TextStyle(
                        fontSize: 17,
                        color: isDark ? Colors.tealAccent[200] : Colors.indigo.shade700,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          _buildActionButton(
            label: "Update App",
            icon: Icons.system_update_alt,
            color: Colors.green.shade600,
            onPressed: () async {
              const url =
                  'https://drive.google.com/file/d/1USY2W0PAjt32feYFrEJipRTPKLj1ySzW/view?usp=sharing';
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cannot launch URL")),
                );
              }
            },
          ),

          const SizedBox(height: 14),

          if (widget.onLogout != null)
            _buildActionButton(
              label: "Logout",
              icon: Icons.logout,
              color: Colors.red.shade600,
              onPressed: () async {
                final confirmed = await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await FirebaseAuth.instance.signOut();
                  widget.onLogout?.call();
                }
              },
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String? value, bool isDark) {
    return Row(
      children: [
        Text(
          "$label:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: isDark ? Colors.tealAccent[100] : Colors.indigo.shade900,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value ?? "-",
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.tealAccent[200] : Colors.indigo.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor: color.withOpacity(0.5),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
