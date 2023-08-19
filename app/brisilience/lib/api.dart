import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

/*
 * This represents short-term danger (i.e. ones that are likely to be an issue 
 * within the next day or so). 
 */
class ShortTermDanger {

}

/*
 * This represents long-term risks that are encountered at the address given.
 * Currently only based on historical flood data, but also designed for
 * bushfire risk and to be expandable.
 */
class LongTermDanger {

}

/*
 * Container object for ShortTermDanger, LongTermDanger and some metadata
 * (such as converting lat/lon to address)
 */
class ApiResponse {

}

/* 
 * This object holds the connection with the API. The API is stateless, but 
 * it is nonetheless an easier way of dealing with it.
 */
class BrisilienceApi {
  late String _baseUrl;

  BrisilienceAPI(String baseUrl) {
    _baseUrl = baseUrl;

    // Check if it is present and valid

  }

  Future<bool> check() async {
    final response = await http.get(Uri.parse('$_baseUrl/ping'));

    return jsonDecode(response.body)['success'] == 1;
  }

}