import "package:flutter/material.dart";
import "package:charts_flutter/flutter.dart" as charts;
import "location.dart";
import "weather_data.dart";

// Contains the widget within the application that actually holds all
// of the state information and updates based on its changes.
class HomePage extends StatefulWidget {
  final String title;

  HomePage({Key key, this.title}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  LocationInfo _userLocation;
  List<Observation> _observations;

  void _requestUpdate() async {
    final location = await getLocation();
    if (location == null) {
      // Normally, we'd want to give an error message to the user, but for the
      // purposes of this simple demo app, we'll just bail.
      return;
    }

    setState(() {
      // Setting this inside setState() will cause a rebuild to update what
      // we know to the user earlier.
      _userLocation = location;
    });

    final observations = await getPressureHistoryByCoord(_userLocation);
    if (observations == null) {
      // See above, re: error messages.
      return;
    }

    setState(() {
      // Rebuild again to update the observations we found.
      _observations = observations;
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
        tooltip: "Update",
        child: Icon(Icons.update),
      ),
    );
  }
}
