import 'package:flutter/material.dart';
import 'package:mango_leap_task/splash.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mango Leap',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          elevation: 0,
          color: Color(0xFF282828),
        ),
        scaffoldBackgroundColor: Color(0xFF282828),
        accentColor: Color(0xFFfdb803),
      ),
      home: SplashScreen(),
    );
  }
}


