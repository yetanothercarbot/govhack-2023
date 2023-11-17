import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/*
 *
 * 
 */
class ApiResponse {
  late String fireRiskAsset;
  late String fireRiskDesc;
  late int longTermFloodRisk;

  late String address;

  ApiResponse(String? responseBody) {
    if (responseBody == null) {
      address = 'Failed.';
    } else {
      final decodedResponse = jsonDecode(responseBody);
      address = decodedResponse['corridor_long_name'];
      longTermFloodRisk = decodedResponse['flood_risk'];
      if (decodedResponse['fire_index'] <= 11) {
        fireRiskAsset = "fire-risk-no-rating.svg";
        fireRiskDesc = "No Rating";
      } else if (decodedResponse['fire_index'] <= 23) {
        fireRiskAsset = "fire-risk-moderate.svg";
        fireRiskDesc = "Moderate";
      } else if (decodedResponse['fire_index'] <= 49) {
        fireRiskAsset = "fire-risk-high.svg";
        fireRiskDesc = "High";
      } else if (decodedResponse['fire_index'] <= 99) {
        fireRiskAsset = "fire-risk-extreme.svg";
        fireRiskDesc = "Extreme";
      } else {
        fireRiskAsset = "fire-risk-catastrophic.svg";
        fireRiskDesc = "Catastrophic";
      }
    }

  }
}

/* 
 * This object holds the connection with the API. The API is stateless, but 
 * it is nonetheless an easier way of dealing with it.
 */
class ServerApi {
  late String _baseUrl;


  ServerApi(String baseUrl) {
    _baseUrl = baseUrl;

    // Check if it is present and valid

  }

  Future<bool> check() async {
    final response = await http.get(Uri.parse('$_baseUrl/ping'));

    return jsonDecode(response.body)['success'] == 1;
  }

  Future<ApiResponse> fetch() async {
    // First get the location
    Position currPos = await _determinePosition();

    print('${currPos.latitude}, ${currPos.longitude}');
    try {
      print('$_baseUrl/riskdata?lat=${currPos.latitude}&long=${currPos.longitude}');
      final response = await http.get(Uri.parse('$_baseUrl/riskdata?lat=${currPos.latitude}&long=${currPos.longitude}'));
      return ApiResponse(response.body);
    } on Error catch (err) {
      print('Failed to call API: $err');
      return ApiResponse(null);
    }
    

  }

}


/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the 
    // App to enable the location services.
    print('Location services are disabled');
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale 
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately. 
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.');
  } 

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}
