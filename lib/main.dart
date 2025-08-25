import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'screens/home_page.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/study_note_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize timezone database
    tz.initializeTimeZones();

    // Get the local timezone using DateTime
    final String timeZoneName = DateTime.now().timeZoneName;
    debugPrint('Local timezone: $timeZoneName');

    // Try to set the local timezone, fallback to UTC if it fails
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Error setting timezone: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // Set a default timezone if something goes wrong
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => StudyNoteService(),
      child: const TodoApp(),
    ),
  );
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> with TickerProviderStateMixin {
  bool _isDarkMode = false;
  bool _isLoading = true;
  bool _showSplash = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Show splash screen for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    // Load theme preference
    final savedTheme = await ThemeService.loadThemePreference();

    setState(() {
      _isDarkMode = savedTheme;
      _isLoading = false;
      _showSplash = false;
    });

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _updateTheme(bool isDarkMode) async {
    setState(() {
      _isDarkMode = isDarkMode;
    });
    await ThemeService.saveThemePreference(isDarkMode);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        if (_showSplash) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        }

        if (_isLoading) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF007AFF),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20.w,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.task_alt_rounded,
                        size: 60.w,
                        color: const Color(0xFF007AFF),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Smart Todo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'Smart Todo',
          debugShowCheckedModeBanner: false,
          themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF007AFF),
              brightness: Brightness.light,
            ),
            fontFamily: 'SF Pro Display',
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              titleTextStyle: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.w),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.w),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF007AFF),
              brightness: Brightness.dark,
            ),
            fontFamily: 'SF Pro Display',
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              titleTextStyle: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.w),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.w),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.w),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
          ),
          home: HomePage(isDarkMode: _isDarkMode, onThemeChanged: _updateTheme),
        );
      },
    );
  }
}
