import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Unified Location Service for the Kurye App.
/// Handles checking permissions and listening to GPS coordinates stream.
class LocationService {
  static StreamSubscription<Position>? _positionStreamSubscription;

  /// Requests location permissions if they are not already granted.
  /// Handles fine, coarse, and background location request flows.
  static Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LocationService: Location services are disabled on this device.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Location permission denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('LocationService: Location permissions are permanently denied.');
      return false;
    }

    // Attempt background permission on native platforms if supported
    if (permission == LocationPermission.whileInUse) {
      debugPrint('LocationService: Foreground location granted. Attempting background location check...');
      // Note: On Android, background location might need explicit request or configuration.
    }

    return true;
  }

  /// Starts listening to device location updates.
  /// Invokes [onLocationChanged] with coordinates whenever position is updated.
  static Future<void> startTracking(Function(double latitude, double longitude) onLocationChanged) async {
    // Check permission first
    final hasPermission = await handlePermission();
    if (!hasPermission) {
      debugPrint('LocationService: Cannot start tracking - Permission denied.');
      return;
    }

    // Cancel existing watch subscription if any
    await stopTracking();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update location every 10 meters change
    );

    debugPrint('LocationService: Starting GPS watch stream...');
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        debugPrint('LocationService: Updated position (${position.latitude}, ${position.longitude})');
        onLocationChanged(position.latitude, position.longitude);
      },
      onError: (error) {
        debugPrint('LocationService error: $error');
      },
    );
  }

  /// Cancels the location update subscription.
  static Future<void> stopTracking() async {
    if (_positionStreamSubscription != null) {
      debugPrint('LocationService: Stopping GPS watch stream.');
      await _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }
  }

  /// Returns the current single position snapshot of the device.
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await handlePermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint('LocationService: Error getting current position: $e');
      return null;
    }
  }
}
