import "package:location/location.dart";
import "package:geocoder/geocoder.dart";

class LocationInfo {
  final double latitude;
  final double longitude;
  final String cityName;

  const LocationInfo({ this.latitude, this.longitude, this.cityName });
}

final _location = Location();

Future<LocationInfo> getLocation() async {
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
        latitude: currentLocation["latitude"],
        longitude: currentLocation["longitude"],
        cityName: cityName
    );
  }
}
