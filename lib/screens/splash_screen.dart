import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      debugPrint('=== Vérification session ===');
      debugPrint('isLoggedIn: ${authService.isLoggedIn()}');
      debugPrint('currentUser: ${authService.currentUser?.username}');
      debugPrint('role: ${authService.currentUser?.role}');
      
      if (authService.isLoggedIn()) {
        if (authService.isAdmin()) {
          debugPrint('Redirection vers admin dashboard');
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          debugPrint('Redirection vers user dashboard');
          Navigator.pushReplacementNamed(context, '/user');
        }
      } else {
        debugPrint('Redirection vers login');
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/bg_img.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 80),
              const Text(
                'Gest-MDP',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}