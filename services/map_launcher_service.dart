import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncherService {
  MapLauncherService._();

  static Future<bool> abrirRotas({
    required double latitude,
    required double longitude,
    required String nome,
    double? originLatitude,
    double? originLongitude,
  }) async {
    final encodedLabel = Uri.encodeComponent(nome);
    final destino = '$latitude,$longitude';

    // Android: tenta abrir o Google Maps diretamente no modo navegação.
    // Não enviamos origem aqui para o Google Maps usar a localização atual do aparelho.
    if (!kIsWeb) {
      final googleNavigationUri = Uri.parse(
        'google.navigation:q=$destino&mode=d',
      );

      if (await _tryLaunch(googleNavigationUri)) {
        return true;
      }
    }

    final origin = originLatitude != null && originLongitude != null
        ? '&origin=$originLatitude,$originLongitude'
        : '';

    // URL oficial de direções do Google Maps. O dir_action=navigate tenta abrir
    // já no fluxo de navegação quando o Google Maps está instalado.
    final googleMapsDirectionsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '$origin'
      '&destination=$destino'
      '&travelmode=driving'
      '&dir_action=navigate',
    );

    if (await _tryLaunch(googleMapsDirectionsUri)) {
      return true;
    }

    final geoUri = Uri.parse('geo:0,0?q=$destino($encodedLabel)');

    if (await _tryLaunch(geoUri)) {
      return true;
    }

    final webSearchUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$destino($encodedLabel)',
    );

    return _tryLaunch(webSearchUri);
  }

  static Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
