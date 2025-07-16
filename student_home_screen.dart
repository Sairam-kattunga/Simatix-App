import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'LiveInboxScreen.dart';
import 'department_subjects_screen.dart';
import 'attendance_calculator_screen.dart';
import 'cgpa_calculator_screen.dart';
import 'course_pdfs_screen.dart';
import 'faculty_directory_screen.dart';
import 'feedback_screen.dart';
import 'welcome_screen.dart';
import 'student_profile_screen.dart';
import 'canteen_reviews_screen.dart';


class StudentHomeScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentHomeScreen({super.key, required this.studentData});

  void _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(Uri.encodeFull(url));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch $url")),
      );
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<_HomeTileData> tiles = [
      _HomeTileData(
        icon: Icons.check_circle,
        title: 'ARMS Portal',
        subtitle: 'Access marks, timetable',
        iconColor: Colors.white,
        bgColor: Colors.indigo,
        onTap: () => _launchURL(
          context,
          'https://arms.sse.saveetha.com/Login.aspx?s=unauth',
        ),
      ),
      _HomeTileData(
        icon: Icons.fastfood,
        title: 'Food Portal',
        subtitle: 'Menu & mess details',
        iconColor: Colors.white,
        bgColor: Colors.orange,
        onTap: () => _launchURL(
          context,
          'https://life.saveetha.com/Login.aspx?type=s',
        ),
      ),

      _HomeTileData(
        icon: Icons.people,
        title: 'Faculty Directory',
        subtitle: 'Contact faculty',
        iconColor: Colors.white,
        bgColor: Colors.blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FacultyDirectoryScreen()),
        ),
      ),
      _HomeTileData(
        icon: Icons.picture_as_pdf,
        title: 'Course PDFs',
        subtitle: 'View/download materials',
        iconColor: Colors.white,
        bgColor: Colors.red,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CoursePDFsScreen()),
        ),
      ),
      _HomeTileData(
        icon: Icons.calculate,
        title: 'CGPA Calculator',
        subtitle: 'Calculate semester CGPA',
        iconColor: Colors.white,
        bgColor: Colors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  CGPACalculatorScreen()),
        ),
      ),
      _HomeTileData(
        icon: Icons.check_circle_outline,
        title: 'Attendance Calculator',
        subtitle: 'Calculate attendance %',
        iconColor: Colors.white,
        bgColor: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceCalculatorScreen()),
        ),
      ),

      _HomeTileData(
        icon: Icons.restaurant_menu,
        title: 'Canteen Food Reviews',
        subtitle: 'View and share feedback',
        iconColor: Colors.white,
        bgColor: Colors.green,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  CanteenReviewsScreen()),
        ),
      ),
      _HomeTileData(
        icon: Icons.library_books,
        title: 'Department Subjects',
        subtitle: 'View subjects by branch',
        iconColor: Colors.white,
        bgColor: Colors.indigo,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) =>  DepartmentSubjectsScreen()),
          );
        },
      ),
      _HomeTileData(
        icon: Icons.live_help,
        title: 'Live Updates',
        subtitle: 'Daily live College updates',
        iconColor: Colors.white,
        bgColor: Colors.indigo,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LiveInboxScreen()),
          );
        },
      ),

      _HomeTileData(
        icon: Icons.feedback,
        title: 'Feedback',
        subtitle: 'Submit suggestions',
        iconColor: Colors.white,
        bgColor: Colors.purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>  FeedbackScreen()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 6,
        backgroundColor: Theme.of(context).colorScheme.surface,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.dashboard, size: 26),
            const SizedBox(width: 10),
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentProfileScreen(
                      onLogout: () => _logout(context),
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: (studentData['profileImageUrl'] != null &&
                    studentData['profileImageUrl'].toString().isNotEmpty)
                    ? NetworkImage(studentData['profileImageUrl'])
                    : null,
                child: (studentData['profileImageUrl'] == null ||
                    studentData['profileImageUrl'].toString().isEmpty)
                    ? Icon(Icons.person, color: Colors.white, size: 24)
                    : null,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  final rows = (tiles.length / crossAxisCount).ceil();
                  final gridHeight = rows * 180.0 + (rows - 1) * 16;

                  return SizedBox(
                    height: gridHeight,
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                      children: tiles.map((tile) => _buildTile(
                        context,
                        icon: tile.icon,
                        title: tile.title,
                        subtitle: tile.subtitle,
                        iconColor: tile.iconColor,
                        bgColor: tile.bgColor,
                        onTap: tile.onTap,
                      )).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color iconColor,
        required Color bgColor,
        required VoidCallback onTap,
      }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).cardColor,
      shadowColor: bgColor.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: bgColor.withOpacity(0.2),
        highlightColor: bgColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: bgColor,
                child: Icon(
                  icon,
                  size: 30,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTileData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final Color bgColor;

  _HomeTileData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.iconColor,
    required this.bgColor,
  });
}
