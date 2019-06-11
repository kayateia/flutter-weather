import "package:http/http.dart" as http;
import "dart:convert" as convert;
import "location.dart";

// Holds a single observation returned from the NWS API. This could be
// expanded to hold more data later, but for now we're only interested
// in barometric pressure in Pa and the weather description.
class Observation {
  final DateTime timestamp;
  final double pressure;
  final String description;

  const Observation({ this.timestamp, this.pressure, this.description });

  String format() {
    final now = DateTime.now();
    final diffHours = now.difference(timestamp).inHours;
    return "$diffHours hours ago - $pressure kPa - $description";
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
Future<String> getStationUrl(LocationInfo location) async {
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
Future<List<Observation>> getPressureHistoryByStationUrl(String stationUrl) async {
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
          timestamp: timestamp,
          pressure: (properties["barometricPressure"]["value"] as int).toDouble() / 1000.0,
          description: properties["textDescription"]
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

Future<List<Observation>> getPressureHistoryByCoord(LocationInfo location) async {
  final url = await getStationUrl(location);
  return await getPressureHistoryByStationUrl(url);
}
