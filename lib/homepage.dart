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

// This class contains the main state and logic for the HomePage widget.
class HomePageState extends State<HomePage> {
  // The user's location, which will be queried from the device.
  LocationInfo _userLocation;

  // The list of weather observations, which will be queried from a REST service.
  List<Observation> _observations;

  // Requests an update of all of our state, including location and weather data.
  // This method is async, which allows us to use "await" instead of a lot of
  // cascading then() calls, but we still get async operation.
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

  // If the state is still in flux, we will show the user a wait prompt with an
  // animating progress indicator.
  List<Widget> _buildProgress(String prompt) {
    return <Widget>[
      Text(prompt),
      CircularProgressIndicator(),
    ];
  }

  // To graph the received weather data, a simple chart. This just shows a line
  // chart of pressure over time, for the requested time period.
  Widget _buildChart() {
    // A chart series turns into a single line of data, and since we are only
    // showing pressure, that's the only series listed.
    final seriesList = [
      charts.Series<Observation, DateTime>(
        id: "Pressure",

        // We'll make the line green.
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,

        // The X axis of the graph.
        domainFn: (Observation obs, _) => obs.timestamp,

        // The Y axis of the graph.
        measureFn: (Observation obs, _) => obs.pressure.toInt(),

        data: _observations,
        displayName: "Pressure in kPa",
      )
    ];

    // The chart will grow to fill its maximum box size, and we have no maximum
    // box size set at this point in the tree. So the Padding and SizedBox will
    // give some bounds to our chart.
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

  // Checks the state of our state data, and builds the appropriate widget tree
  // to match; until we have all of the data, we'll
  List<Widget> _buildContent(BuildContext context) {
    if (_userLocation == null) {
      return _buildProgress("Finding you...");
    } else if (_observations == null) {
      return _buildProgress("Getting data...");
    } else {
      return <Widget>[
        // The user's city and postal code in a big font.
        Text(_userLocation.cityName, style: Theme.of(context).textTheme.display1),

        // Pull in all of the observations as small text lines.
        for (final obs in _observations) Text(obs.format()),

        // And the chart itself.
        _buildChart(),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildContent(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // The user can press this button to manually update. This small test
        // app currently does not update on its own.
        onPressed: _requestUpdate,
        tooltip: "Update",
        child: Icon(Icons.update),
      ),
    );
  }
}
