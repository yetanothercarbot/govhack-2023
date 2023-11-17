
import 'package:geolocator/geolocator.dart';
import 'package:seqprepare/api.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seqprepare/fire_locations_api.dart';
import 'ui.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
          title: 'SEQPrepare',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: MyHomePage(title: "SEQPrepare"),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  FireLocationApi fireApi = FireLocationApi();
  ServerApi api = ServerApi("https://api.seqprepare.xyz");
  late Future<Position> pos;
  late Future<ApiResponse> response;
  late Future<Map<String, dynamic>> fires;
  
  @override
  MyAppState() {
    response = api.fetch();
    fires = fireApi.fetch();
    pos = determinePosition();
  }

}
