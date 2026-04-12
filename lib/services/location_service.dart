import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<Position?> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    // This would use a geocoding service
    return '$lat, $lng';
  }

  static String formatDuration(double distanceKm) {
    // Assume average speed of 15 km/h for delivery
    const double averageSpeedKmh = 15.0;
    final double timeHours = distanceKm / averageSpeedKmh;
    final int hours = timeHours.floor();
    final int minutes = ((timeHours - hours) * 60).round();
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000; // Convert to km
  }
}
