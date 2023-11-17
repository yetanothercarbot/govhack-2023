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

    return FutureBuilder<Map<String, dynamic>>(
      future: fires,
      builder: (context, snapshot) {
        var points = <Marker>[];
        if(snapshot.data == null) {
          return Placeholder();
        }
        for (final feature in snapshot.data!['features']) {
          if (feature['geometry']['type'] == "Point") {
            // Add it to the points layer
            points.add(Marker(
              point: LatLng(feature['geometry']['coordinates'][1], feature['geometry']['coordinates'][0]),
              builder: (context) => const Icon(Icons.local_fire_department, size: 30, color: Color.fromARGB(255, 216, 135, 13),), 
            ));
          } else if (feature['geometry']['type'] == "Polygon") {
            // Add it to the polygon layer
          }
        }

        print(points);

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
            MarkerLayer(
              markers: points,
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