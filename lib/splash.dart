import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mango_leap_task/contact.dart';
import 'package:mango_leap_task/user.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    startTime();
  }

  startTime() async {
    var duration = new Duration(seconds: 2);
    return new Timer(duration, route);
  }

  route() {
    Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => UserScreen()
    )
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0x33282828),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(8),
          child: Image.asset('assets/images/mangoleap.png'),
        ),
      ),
    );
  }
}
