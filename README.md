# Flutter Weather

This project is a sample Flutter/Dart app demonstrating how to find the
user's location from the device, look up weather information from the
NWS, and display a table and a graph of the data. Currently, it only
deals in barometric pressure, so the app is called `pressure`. This
might change later.

The scope of this sample is very limited since it was mostly an exercise
in teaching myself Flutter/Dart over a weekend, but perhaps it will be
useful for someone who finds it! As implied in that statement, I am
not an expert by any means. But hopefully, if you're reading this, you
can find something useful in the example code to help your own project.

<p align="center">
  <img src="https://github.com/kayateia/flutter-weather/blob/master/screenshot.png?raw=true" alt="Screen shot from Android version"/>
</p>

## Caveats

* I have not tested this with iOS (only Android Pie on a Pixel 1)
* I have not tested this outside of the US (or really anywhere besides
my home in Seattle)

## License

This project is licensed under the MIT license.

## Getting Started

You'll need to have a working Flutter setup, preferably on Android
Studio. More information about that setup can be found here:

- [Lab: Write your first Flutter app](https://flutter.io/docs/get-started/codelab)
- [Online Flutter documentation](https://flutter.io/docs)

After opening the project in Android Studio, you may need to open the
`pubspec.yaml` and click `Packages get`. You should then be able to
start the app in a connected Android device.

## Code Tour

The code is organized into four main `lib` modules, and one `test` module.

#### lib:_main.dart_

The app entry point, and the top level app widget live here. This also
creates location and weather lookup objects for a real device.

#### lib:_homepage.dart_

Implements a stateful widget that contains most of the app's user interface.

A top level `build()` method takes care of putting together all of the
pieces, which are chosen based on the app's current state. Before
information is available, the user is shown a spinner with some text
describing what the app is waiting for. (**Note** that the app does not
auto-request the information, but waits for the user to tap the refresh
button. This is done to make it simpler to control the execution for
debugging and inspection, since this is a sample app and not a production
app.)

When the user taps the refresh button, `_requestUpdate()` is called,
which kicks off an async update process using the location and weather
data collector objects that were passed down from the app container.

The final widget build pulls together a larger title text with the
name of the user's city and postal code, a table of observations from
the NWS API, and a graph showing the past few hours of values.

#### lib:_location.dart_

The `LocationInfo` class is defined here to contain information about
the user's location. As the raw Dart `location` API returns a simple
map from string to value, the `RealLocation` class converts that "soft"
data structure into something more strongly typed for the rest of the
app to use. `FakeLocation` is also available for unit testing, and to
let you plug in synthetic locations for app testing.

#### lib:_weather_data.dart_

The `Observation` class contains strongly typed information about a
single weather observation; the weather data objects will return
several. (Currently, it is hard-coded to four hours of data, but this
could be changed to be more flexible.) `Observation` also provides a
formatting function for the tabular display in the UI.

`RealWeather` implements an actual RESTful client which talks to the NWS
REST services. (As of this writing, it does not require an explicit
API key, but they do request mentioning the client name and contact
info in the User-Agent header; if you fork this project, please change
the headers to have your info.) `FakeWeather` implements a mock for
unit testing, and to let you plug in synthetic data for app testing.

#### test:_widget\_test.dart_

Contains a minimally updated version of the default Flutter test suite,
adapted for the Weather Pressure app. A test app container widget is
created, which passes in fake location and weather objects. A user
tap on the refresh button is simulated, and the results are checked.
 