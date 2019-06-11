import "package:location/location.dart";
import "package:geocoder/geocoder.dart";

// A data class that will hold information retrieved about the user's location.
// The "location" library returns only maps, so this is much more strongly typed.
class LocationInfo {
  // The user's GPS coordinates.
  final double latitude;
  final double longitude;

  // This is free form, but in practice, it's the user's city name and postal code.
  final String cityName;

  const LocationInfo({ this.latitude, this.longitude, this.cityName });
}

final _location = Location();

// Returns the user's location information asynchronously, or null if it can't
// be determined.
Future<LocationInfo> getLocation() async {
  var currentLocation = <String, double> { };
  var cityName = "";
  try {
    currentLocation = await _location.getLocation();
    final coordinates = Coordinates(currentLocation["latitude"], currentLocation["longitude"]);

    // The geocoder library can also tell us geopolitical information about
    // coordinates, such as the city name and postal code.
    final address = await Geocoder.local.findAddressesFromCoordinates(coordinates);
    final first = address.first;
    cityName = "${first.locality} ${first.postalCode}";
  } catch (e) {
    currentLocation = null;
  }

  // If we had successful queries above, then convert to our typed data class.
  if (currentLocation == null) {
    return null;
  } else {
    return LocationInfo(
        latitude: currentLocation["latitude"],
        longitude: currentLocation["longitude"],
        cityName: cityName
    );
  }
}
