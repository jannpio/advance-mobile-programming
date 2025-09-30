import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pioquinto_advmobprog/screens/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:pioquinto_advmobprog/firebase_options.dart';
import 'package:pioquinto_advmobprog/providers/theme_provider.dart';
import 'package:pioquinto_advmobprog/screens/home_screen.dart';
import 'package:pioquinto_advmobprog/screens/login_screen.dart';
import 'package:pioquinto_advmobprog/screens/profile_screen.dart';
import 'package:pioquinto_advmobprog/screens/register_screen.dart';
import 'package:pioquinto_advmobprog/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) async {
    await dotenv.load(fileName: 'assets/.env'); 
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MainApp());
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          final themeModel = context.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'Blog App',
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/chats': (context) => const ChatScreen(),
            },
          );
        },
      ),
    );
  }
}