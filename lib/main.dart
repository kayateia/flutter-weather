import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:charts_flutter/flutter.dart' as charts;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather Pressure',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Weather Pressure'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class LocationInfo {
  final double latitude;
  final double longitude;
  final String cityName;

  const LocationInfo(this.latitude, this.longitude, this.cityName);
}

// Holds a single observation returned from the NWS API. This could be
// expanded to hold more data later, but for now we're only interested
// in barometric pressure in Pa and the weather description.
class Observation {
  final DateTime timestamp;
  final double pressure;
  final String description;

  const Observation(this.timestamp, this.pressure, this.description);

  String format() {
    final now = DateTime.now();
    final diffHours = now.difference(timestamp).inHours;
    return "$diffHours hours ago - $pressure kPa - $description";
  }
}

class _MyHomePageState extends State<MyHomePage> {
  LocationInfo _userLocation;
  List<Observation> _observations;
  final _location = Location();

  void _requestUpdate() {
    // assert(_userLocation == null);
    _getLocation().then((LocationInfo value) {
      setState(() {
        // This call to setState tells the Flutter framework that something has
        // changed in this State, which causes it to rerun the build method below
        // so that the display can reflect the updated values. If we changed
        // _counter without calling setState(), then the build method would not be
        // called again, and so nothing would appear to happen.
        _userLocation = value;
      });

      print("Getting station from ${_userLocation.latitude}. ${_userLocation.longitude}");
      _getStationUrl(_userLocation).then((String url) {
        print("Getting observations from $url");
        _getPressureHistory(url).then((List<Observation> observations) {
          if (observations != null) {
            print("${observations.length} Observations gotten");
          } else {
            print("obs null");
          }
          setState(() {
            _observations = observations;
          });
        });
      });
    });
  }

  List<Widget> _buildProgress(String prompt) {
    return <Widget>[
      Text(prompt),
      CircularProgressIndicator()
    ];
  }

  Widget _buildChart() {
    final seriesList = [
      charts.Series<Observation, DateTime>(
        id: "Pressure",
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (Observation obs, _) => obs.timestamp,
        measureFn: (Observation obs, _) => obs.pressure.toInt(),
        data: _observations,
        displayName: "Pressure in kPa",
      )
    ];

    return Padding(
      padding: EdgeInsets.all(32.0),
      child: SizedBox(
        height: 200.0,
        child: charts.TimeSeriesChart(
          seriesList,
          animate: false,
          dateTimeFactory: const charts.LocalDateTimeFactory(),
        ),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    if (_userLocation == null) {
      return _buildProgress("Finding you...");
    } else if (_observations == null) {
      return _buildProgress("Getting data...");
    } else {
      return <Widget>[
        Text(_userLocation.cityName, style: Theme.of(context).textTheme.display1),
        for (final obs in _observations) Text(obs.format()),
        _buildChart(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // _requestUpdate();

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildContent(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _requestUpdate,
        tooltip: 'Get Location',
        child: Icon(Icons.update),
      ),
    );
  }

  Future<LocationInfo> _getLocation() async {
    var currentLocation = <String, double> { };
    var cityName = "";
    try {
      currentLocation = await _location.getLocation();

      final coordinates = Coordinates(currentLocation["latitude"], currentLocation["longitude"]);
      final address = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      final first = address.first;
      cityName = "${first.locality} ${first.postalCode}";
    } catch (e) {
      currentLocation = null;
    }

    if (currentLocation == null) {
      return null;
    } else {
      return LocationInfo(
        currentLocation["latitude"],
        currentLocation["longitude"],
        cityName
      );
    }
  }

  final _headers = {
    // Ask for data in a JSON form.
    "Accept": "application/geo+json",

    // The NWS requests this header as a condition of using their APIs.
    "User-Agent": "Flutter test app 'pressure': https://github.com/kayateia/",
  };

  /*
    The relevant part of the JSON that this returns is in this structure:

    {
      "observationStations": [
        "url",
        "url",
        ...
      ]
    }

    Observation stations seem to be sorted by distance from the specified point.

    We'll just grab the first one. It's possible that the list may be empty for
    a given GPS coordinate (or even a bad GPS coordinate), but for the sake of
    simplicity in this learning app, we'll just assume there's at least one.
   */
  Future<String> _getStationUrl(LocationInfo location) async {
    final response = await http.get(
      "https://api.weather.gov/points/${location.latitude}%2C${location.longitude}/stations",
      headers: _headers
    );

    if (response.statusCode == 200) {
      final json = convert.jsonDecode(response.body);
      return json["observationStations"][0];
    } else {
      return null;
    }
  }

  /*
    The relevant part of the JSON that this returns is in this structure:

    {
      "features": [
        {
          "properties": {
            "timestamp": "<timestamp in ISO 8601>",
            "textDescription": "Overcast With a Chance of Brimstone",
            "barometricPressure": {
              "value": 12345,
              "unitCode": "unit:Pa"
            }
          }
        }
      ]
    }

    There is a lot more there, but we're not taking it for this simple app.
   */
  Future<List<Observation>> _getPressureHistory(String stationUrl) async {
    // In practice, the resolution of data we will get back is one hour. So we have to
    // request a few hours in order to get much of anything.
    final now = DateTime.now();
    final requestLimit = now.subtract(Duration(hours: 4));

    // NWS doesn't allow us to pass milliseconds.
    final requestLimitString = requestLimit
        .toUtc()
        .toIso8601String()
        .substring(0, 19)
        + "Z";

    print("$stationUrl/observations?start=$requestLimitString");
    final response = await http.get(
      "$stationUrl/observations?start=$requestLimitString",
        headers: _headers
    );

    if (response.statusCode == 200) {
      final json = convert.jsonDecode(response.body);
      final features = json["features"];

      // Ideally, we would check properties["barometricPressure"]["unitCode"] to
      // verify that it's "unit:Pa", but since this is a simple learning app,
      // I'm skipping that check here.
      final convertedFeatures = features.map<Observation>((feature) {
        final properties = feature["properties"];
        final timestamp = DateTime.parse(properties["timestamp"]);
        return Observation(
          timestamp,
          (properties["barometricPressure"]["value"] as int).toDouble() / 1000.0,
          properties["textDescription"]
        );
      }).toList();

      // This sorts in descending date/time so that the newest observations are first.
      convertedFeatures.sort(
        (Observation obs1, Observation obs2) => obs2.timestamp.difference(obs1.timestamp).inSeconds
      );

      return convertedFeatures;
    } else {
      print(response.statusCode);
      print(response.body);
      return null;
    }
  }
}
