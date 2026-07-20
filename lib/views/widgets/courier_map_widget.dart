import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CourierMapWidget extends StatelessWidget {
  final double courierLat;
  final double courierLon;
  final double restaurantLat;
  final double restaurantLon;
  final String courierName;
  final String restaurantName;

  const CourierMapWidget({
    super.key,
    required this.courierLat,
    required this.courierLon,
    required this.restaurantLat,
    required this.restaurantLon,
    required this.courierName,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    final courierLatLng = LatLng(courierLat, courierLon);
    final restaurantLatLng = LatLng(restaurantLat, restaurantLon);
    
    // Calculate center between both points
    final centerLat = (courierLat + restaurantLat) / 2;
    final centerLon = (courierLon + restaurantLon) / 2;
    final centerLatLng = LatLng(centerLat, centerLon);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kurye.kurye_app',
                // Dark mode tint for modern aesthetics
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      -0.2126, -0.7152, -0.0722, 0, 255,
                      0,      0,      0,      1, 0,
                    ]),
                    child: tileWidget,
                  );
                },
              ),
              PolylineLayer(
                polylines: <Polyline<Object>>[
                  Polyline<Object>(
                    points: <LatLng>[courierLatLng, restaurantLatLng],
                    color: const Color(0xFFA855F7),
                    strokeWidth: 4.0,
                    pattern: StrokePattern.dashed(segments: const [8, 4]),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Courier Marker
                  Marker(
                    point: courierLatLng,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9333EA),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(LucideIcons.bike, color: Colors.white, size: 14),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            courierName,
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Restaurant Marker
                  Marker(
                    point: restaurantLatLng,
                    width: 60,
                    height: 60,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(LucideIcons.chefHat, color: Colors.white, size: 14),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            restaurantName,
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '© OpenStreetMap',
                style: TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ),
          )
        ],
      ),
    );
  }
}
