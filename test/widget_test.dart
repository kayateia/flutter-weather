import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pressure/homepage.dart';
import "package:pressure/location.dart";
import "package:pressure/weather_data.dart";

class TestApp extends StatelessWidget {
  final LocationInfo _locationInfo;
  final List<Observation> _observations;

  TestApp(this._locationInfo, this._observations);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "test",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(
        title: "test",
        location: FakeLocation(_locationInfo),
        weather: FakeWeather(_observations),
      ),
    );
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Make some fake location data and observations.
    final location = LocationInfo(
      latitude: 1.0,
      longitude: -1.0,
      cityName: "Test",
    );
    final obs = <Observation>[
      Observation(
        timestamp: DateTime.now(),
        pressure: 100.0,
        description: "Clear",
      ),
    ];

    // Build our app and trigger a frame.
    await tester.pumpWidget(TestApp(location, obs));

    // Verify that our text shows a loading circle by default.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Tape the update icon to trigger a frame.
    await tester.tap(find.byIcon(Icons.update));
    await tester.pump();

    // Verify that our text now shows the city name.
    expect(find.text("Test"), findsOneWidget);
  });
}
