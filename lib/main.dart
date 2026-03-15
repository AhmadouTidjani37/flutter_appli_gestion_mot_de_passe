// main.dart
import 'package:flutter/material.dart';
import 'package:gest_mdp/firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/encryption_service.dart';
import 'services/google_drive_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/user/user_dashboard.dart';
import 'screens/splash_screen.dart'; 
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  

  final databaseService = DatabaseService();
  await databaseService.database;
  final authService = AuthService();
  await authService.init(); 
  final googleDriveService = GoogleDriveService();
  await googleDriveService.init(); 
  
  runApp(MyApp(
    authService: authService,
    googleDriveService: googleDriveService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final GoogleDriveService googleDriveService;
  
  const MyApp({
    super.key, 
    required this.authService,
    required this.googleDriveService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        ChangeNotifierProvider<GoogleDriveService>.value(value: googleDriveService), // CORRECTION ICI
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<EncryptionService>(create: (_) => EncryptionService()),
      ],
      child: MaterialApp(
        title: 'Gest-MDP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.purple, width: 2),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/admin': (context) => AdminDashboard(),
          '/user': (context) => UserDashboard(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: Text('Page non trouvée'),
              ),
            ),
          );
        },
      ),
    );
  }
}