import "package:flutter/material.dart";
import "homepage.dart";

void main() => runApp(PressureApp());

// This widget represents the root of the Flutter application.
class PressureApp extends StatelessWidget {
  final _appTitle = "Weather Pressure";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: _appTitle),
    );
  }
}
