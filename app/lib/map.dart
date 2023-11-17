import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:seqprepare/main.dart';
import 'package:url_launcher/url_launcher.dart';

class FiresMap extends StatelessWidget {
  const FiresMap({
    super.key,
    required this.mapController,
    required this.screenSize
  });

  final MapController mapController;
  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    var fires = context.watch<MyAppState>().fires;
    var pos = context.watch<MyAppState>().pos;

    return FutureBuilder<Map<String, dynamic>>(
      future: fires,
      builder: (context, snapshot) {
        var points = <Marker>[];
        var polygons = <Polygon>[];
        if(snapshot.data == null) {
          return Placeholder();
        }
        for (final feature in snapshot.data!['features']) {
          if (feature['geometry']['type'] == "Point") {
            // Add it to the points layer
            points.add(Marker(
              point: LatLng(feature['geometry']['coordinates'][1], feature['geometry']['coordinates'][0]),
              builder: (context) => GestureDetector(
                child: const Icon(Icons.local_fire_department, size: 30, color: Color.fromARGB(255, 216, 135, 13),),
                onTap: () {
                  showDialog(
                    context: context, 
                    builder: (BuildContext context) {
                      // Potential improvement: Show data such as last update and number of vehicles en route and on scene.
                      return AlertDialog(
                        title: Text(feature['properties']['WarningTitle']),
                        content: Text(feature['properties']['CallToAction']),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(context, 'OK'),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    }
                  );
                },
              ),
            ));
          } else if (feature['geometry']['type'] == "Polygon") {
            // Add it to the polygon layer
            // Polygons cannot be tapped for more info - shortcoming of flutter_map currently.
            // There are few enough polygons that it could be possible to search through polygons manually
            // upon tap, but not implemented (yet).
            polygons.add(Polygon(
              points: [for (var i in feature['geometry']['coordinates'][0]) LatLng(i[1], i[0])],
              borderColor: Color.fromARGB(255, 216, 135, 13),
              borderStrokeWidth: 2,
              color: Color.fromARGB(120, 216, 135, 13),
              isFilled: true
            ));
          }
        }

        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            screenSize: screenSize,
            center: const LatLng(-22.107471, 149.50843),
            zoom: 6,
            maxZoom: 18,
            maxBounds: LatLngBounds(
                const LatLng(-6.697788086491729, 135.62482150691713),
                const LatLng(-31.324481038082332, 162.0974699871303)),
            interactiveFlags:
                InteractiveFlag.all - InteractiveFlag.rotate,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'xyz.crashmap.app',
              maxNativeZoom: 18,
            ),
            PolygonLayer(
              polygons: polygons,
            ),
            MarkerLayer(
              markers: points,
            ),
            FutureBuilder(
              future: pos,
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return MarkerLayer();
                }
                return MarkerLayer(
                  markers: [
                    Marker(point: LatLng(snapshot.data!.latitude, snapshot.data!.longitude), builder: (context) => const Icon(Icons.location_pin, size: 20, color: Colors.black,), )
                  ],
                );
              }
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                ),
              ],
            ),
          ],
        );
      }
    );
  }

}