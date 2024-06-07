import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class CurrentLocation {
  Future<Position?> getCurrentLocation() async {
    final status = await Permission.location.status;
    if (!status.isGranted) {
      final result = await Permission.location.request();
      if (result != PermissionStatus.granted) {
        return null;
      }
    }
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }
}
