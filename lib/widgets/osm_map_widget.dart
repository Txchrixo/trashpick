import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget réutilisable pour afficher une carte OpenStreetMap
class OsmMapWidget extends StatelessWidget {
  final LatLng center;
  final double zoom;
  final List<Marker> markers;
  final MapController? mapController;
  final void Function(MapController)? onMapCreated;

  const OsmMapWidget({
    super.key,
    required this.center,
    this.zoom = 13.0,
    this.markers = const [],
    this.mapController,
    this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    final controller = mapController ?? MapController();

    // Appeler onMapCreated si fourni
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onMapCreated != null) {
        onMapCreated!(controller);
      }
    });

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        // Couche de tuiles OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.trashpicker.app',
          maxZoom: 19,
          maxNativeZoom: 19,
        ),
        // Couche de markers
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers,
          ),
      ],
    );
  }
}
