import 'package:geolocator/geolocator.dart';

class LocationAccessResult {
  final bool granted;
  final String message;
  final bool serviceDisabled;
  final bool permanentlyDenied;

  const LocationAccessResult._({
    required this.granted,
    required this.message,
    this.serviceDisabled = false,
    this.permanentlyDenied = false,
  });

  const LocationAccessResult.granted()
      : this._(
          granted: true,
          message: 'Permissão de localização concedida.',
        );

  const LocationAccessResult.serviceDisabled()
      : this._(
          granted: false,
          serviceDisabled: true,
          message: 'Ative a localização/GPS do dispositivo para usar o mapa com rotas reais.',
        );

  const LocationAccessResult.denied()
      : this._(
          granted: false,
          message: 'Permissão de localização negada. Para usar as rotas reais, ative a permissão nas configurações do aplicativo.',
        );

  const LocationAccessResult.deniedForever()
      : this._(
          granted: false,
          permanentlyDenied: true,
          message: 'A permissão foi bloqueada. Ative a localização manualmente nas configurações do aplicativo.',
        );
}

class LocationService {
  static const LocationSettings _streamSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 8,
  );

  Future<LocationAccessResult> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const LocationAccessResult.serviceDisabled();
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationAccessResult.denied();
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationAccessResult.deniedForever();
    }

    return const LocationAccessResult.granted();
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: _streamSettings,
    );
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}
