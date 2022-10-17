import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:live_streaming/firebase/auth_service.dart';
import 'package:live_streaming/screens/home_page.dart';
import 'package:live_streaming/screens/login_page.dart';
import 'package:live_streaming/providers/user_provider.dart';
import 'package:live_streaming/utils/colors.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Streaming',
      theme: ThemeData.light().copyWith(
          scaffoldBackgroundColor: backgroundColor,
          appBarTheme: AppBarTheme.of(context).copyWith(
            backgroundColor: backgroundColor,
            elevation: 0,
            titleTextStyle: const TextStyle(
                color: primaryColor, fontSize: 20, fontWeight: FontWeight.w600),
            iconTheme: const IconThemeData(
              color: primaryColor,
            ),
          )),
      routes: {
        LoginPage.routeName: (context) => const LoginPage(),
        HomePage.routeName: (context) => const HomePage(),
      },
      home: AuthService().handleAuthState(),
    );
  }
}
