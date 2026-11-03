import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/route_model.dart';

class RouteService {
  RouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RouteModel?> buscarRota({
    required LatLng origem,
    required LatLng destino,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origem.longitude},${origem.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=geojson&alternatives=false&steps=false',
    );

    try {
      final response = await _client.get(url).timeout(
            const Duration(seconds: 18),
          );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['code'] != 'Ok' || data['routes'] is! List) {
        return null;
      }

      final routes = data['routes'] as List;

      if (routes.isEmpty) {
        return null;
      }

      final route = Map<String, dynamic>.from(routes.first as Map);
      final geometry = Map<String, dynamic>.from(route['geometry'] as Map);
      final coordinates = geometry['coordinates'] as List;

      final points = coordinates.map((coordinate) {
        final item = coordinate as List;
        final longitude = (item[0] as num).toDouble();
        final latitude = (item[1] as num).toDouble();
        return LatLng(latitude, longitude);
      }).toList();

      if (points.length < 2) {
        return null;
      }

      return RouteModel(
        origem: origem,
        destino: destino,
        pontos: points,
        distanciaMetros: (route['distance'] as num?)?.toDouble() ?? 0,
        duracaoSegundos: (route['duration'] as num?)?.toDouble() ?? 0,
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
