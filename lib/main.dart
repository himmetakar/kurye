import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'views/app_shell.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safe Firebase core initialization fallback
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization skipped or not configured: $e');
  }

  // Initialize push notification listener logic
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kurye App Lojistik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4F46E5), // Indigo 600
          secondary: Color(0xFF6366F1), // Indigo 500
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 13),
          bodyMedium: TextStyle(color: Color(0xFF475569), fontSize: 11),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF4F46E5);
            }
            return null;
          }),
        ),
      ),
      home: const AppShell(),
    );
  }
}
