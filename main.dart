import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_fixed_new/screens/AppBlockedScreen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'screens/student_home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/student_login_screen.dart';
import 'screens/student_register_screen.dart';
import 'theme_notifier.dart';
import 'dart:math';
import 'package:flutter/material.dart';


// Particle model class
class Particle {
  Offset startPosition;
  double size;
  double speed; // vertical speed
  double horizontalDrift;
  Color color;

  Particle({
    required this.startPosition,
    required this.size,
    required this.speed,
    required this.horizontalDrift,
    required this.color,
  });

  // Factory to create random particle within bounds
  factory Particle.random(Random random) {
    return Particle(
      startPosition: Offset(random.nextDouble(), random.nextDouble()),
      size: 2 + random.nextDouble() * 6,
      speed: 0.01 + random.nextDouble() * 0.02,
      horizontalDrift: -0.005 + random.nextDouble() * 0.01,
      color: Colors.blue.withOpacity(0.3 + random.nextDouble() * 0.5),
    );
  }

  // Calculate position at time t (0..1)
  Offset positionAt(double t) {
    double dx = (startPosition.dx + horizontalDrift * t) % 1.0;
    double dy = (startPosition.dy - speed * t);
    if (dy < 0) dy += 1.0;
    return Offset(dx, dy);
  }
}

// CustomPainter for particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress; // 0..1 animation progress

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var particle in particles) {
      final pos = particle.positionAt(progress);
      final offset = Offset(pos.dx * size.width, pos.dy * size.height);
      paint.color = particle.color;
      canvas.drawCircle(offset, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}


// Create a FlutterLocalNotificationsPlugi


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔥 Remote Config setup
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: Duration.zero, // Force fetch every time
  ));
  await remoteConfig.setDefaults({'app_enabled': true});
  await remoteConfig.fetchAndActivate();

  final isEnabled = remoteConfig.getBool('app_enabled');
  print('✅ app_enabled from Remote Config: $isEnabled');


  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: isEnabled
          ? const SimatixApp()
          : const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AppBlockedScreen(),
      ),
    ),
  );
}


class SimatixApp extends StatelessWidget {
  const SimatixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Simatix',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeNotifier.currentTheme,
          debugShowCheckedModeBanner: false,
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/login': (context) => const StudentLoginScreen(),
            '/detailsEntry': (context) => const StudentRegisterScreen(),
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

// ✅ COMBINED SplashScreen: animated + logic
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  bool _hasNavigated = false;

  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late AnimationController _textController;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // LOGO scaling
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 1.0, end: 2.8).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutCubic),
    );

    // TEXT fade in
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _startAnimations();
    Future.delayed(const Duration(milliseconds: 3000), _decideNavigation);
  }

  Future<void> _startAnimations() async {
    await _logoController.forward();
    await _textController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _decideNavigation() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      Navigator.pushReplacementNamed(context, '/welcome');
    } else if (currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      final regNo = prefs.getString('regNo');
      if (regNo == null) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final studentData = {
          'regNo': regNo,
          'name': prefs.getString('name') ?? 'No Name',
          'email': prefs.getString('email') ?? 'No Email',
          'year': prefs.getString('year') ?? 'N/A',
          'department': prefs.getString('department') ?? 'N/A',
          'profileImageUrl': prefs.getString('profileImageUrl') ?? '',
        };

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StudentHomeScreen(studentData: studentData),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Centered and scaled logo
          Center(
            child: AnimatedBuilder(
              animation: _logoScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScale.value,
                  child: SizedBox(
                    width: size.width * 0.35,
                    child: Image.asset(
                      'assets/icons/logo.jpeg',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ),
          // Faded in text after logo animation
          Positioned(
            bottom: size.height * 0.1,
            child: FadeTransition(
              opacity: _textFade,
              child: Text(
                'SIMATIX',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  fontFamily: 'RobotoCondensed',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
