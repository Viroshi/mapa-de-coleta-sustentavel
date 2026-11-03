import 'package:latlong2/latlong.dart';

class RouteModel {
  final LatLng origem;
  final LatLng destino;
  final List<LatLng> pontos;
  final double distanciaMetros;
  final double duracaoSegundos;

  const RouteModel({
    required this.origem,
    required this.destino,
    required this.pontos,
    required this.distanciaMetros,
    required this.duracaoSegundos,
  });

  String get distanciaFormatada {
    if (distanciaMetros >= 1000) {
      return '${(distanciaMetros / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
    }

    return '${distanciaMetros.round()} m';
  }

  String get duracaoFormatada {
    final minutos = (duracaoSegundos / 60).round();

    if (minutos < 60) {
      return '$minutos min';
    }

    final horas = minutos ~/ 60;
    final resto = minutos % 60;

    if (resto == 0) {
      return '${horas}h';
    }

    return '${horas}h ${resto}min';
  }
}
