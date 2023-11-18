import 'dart:convert';

import 'package:http/http.dart' as http;

class FireLocationApi {
  // late points;

  FireLocationApi();

  Future<Map<String, dynamic>> fetch() async {
    final response = await http.get(Uri.parse("https://api.seqprepare.xyz/currentfires"));
    return jsonDecode(response.body);
  }
}