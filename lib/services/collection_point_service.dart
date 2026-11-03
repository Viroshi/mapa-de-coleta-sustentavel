import 'dart:async';
import 'dart:convert';

import 'package:flutter_overpass/flutter_overpass.dart';
import 'package:latlong2/latlong.dart';

import '../data/local_collection_points.dart';
import '../models/place_model.dart';
import 'firebase_service.dart';

/// Reúne as fontes de pontos de coleta usadas pelo mapa.
///
/// O Firestore guarda os pontos administrados pelo aplicativo. A base local e
/// o OpenStreetMap complementam esses dados com pontos públicos já conhecidos.
/// As fontes são combinadas mesmo quando o Firebase está configurado.
class CollectionPointService {
  final FlutterOverpass _overpass = FlutterOverpass();
  final FirebaseService _firebase = FirebaseService.instance;

  static const String cidade = 'Teresina';
  static const Duration _osmCacheDuration = Duration(minutes: 10);

  List<PlaceModel>? _osmCache;
  DateTime? _osmCacheAt;

  Future<List<PlaceModel>> buscarPorTexto(String texto) async {
    final termo = texto.trim();

    if (termo.isEmpty) {
      return buscarTodosEcopontos();
    }

    final categoria = _detectarCategoria(termo);
    if (categoria != null) {
      return buscarCategoria(categoria);
    }

    final todos = await buscarTodosEcopontos();
    return todos.where((ponto) => ponto.contemTexto(termo)).toList();
  }

  Future<List<PlaceModel>> buscarCategoria(String categoria) async {
    final normalizada = _normalizar(categoria);

    if (normalizada == 'todos') {
      return buscarTodosEcopontos();
    }

    final todos = await buscarTodosEcopontos();
    return todos
        .where((ponto) => _pontoCorrespondeCategoria(ponto, normalizada))
        .toList();
  }

  Future<List<PlaceModel>> buscarTodosEcopontos() async {
    final local = LocalCollectionPoints.todos
        .where((ponto) => ponto.dentroDoEscopoDoTcc)
        .toList();

    final futures = <Future<List<PlaceModel>>>[_buscarPontosOpenStreetMap()];

    if (_firebase.isConfigured) {
      futures.add(_firebase.listarPontosValidados());
    }

    final resultados = await Future.wait(futures);
    final osm = resultados.first;
    final firebase = resultados.length > 1
        ? resultados[1]
        : const <PlaceModel>[];

    // A ordem define a prioridade em caso de duplicidade. Um ponto validado
    // no Firebase deve prevalecer sobre uma referência local/externa.
    return _removerDuplicados([...firebase, ...local, ...osm]);
  }

  Future<List<PlaceModel>> _buscarPontosOpenStreetMap() async {
    final cache = _osmCache;
    final cacheAt = _osmCacheAt;

    if (cache != null &&
        cacheAt != null &&
        DateTime.now().difference(cacheAt) < _osmCacheDuration) {
      return List<PlaceModel>.from(cache);
    }

    final query =
        '''
[out:json][timeout:25];
area["name"="$cidade"]["boundary"="administrative"]->.searchArea;
(
  node["amenity"="recycling"]["recycling:batteries"="yes"](area.searchArea);
  way["amenity"="recycling"]["recycling:batteries"="yes"](area.searchArea);
  relation["amenity"="recycling"]["recycling:batteries"="yes"](area.searchArea);
  node["shop"="recycling"]["recycling:batteries"="yes"](area.searchArea);
  way["shop"="recycling"]["recycling:batteries"="yes"](area.searchArea);
  relation["shop"="recycling"]["recycling:batteries"="yes"](area.searchArea);

  node["amenity"="recycling"]["recycling:electronics"="yes"](area.searchArea);
  way["amenity"="recycling"]["recycling:electronics"="yes"](area.searchArea);
  relation["amenity"="recycling"]["recycling:electronics"="yes"](area.searchArea);
  node["shop"="recycling"]["recycling:electronics"="yes"](area.searchArea);
  way["shop"="recycling"]["recycling:electronics"="yes"](area.searchArea);
  relation["shop"="recycling"]["recycling:electronics"="yes"](area.searchArea);

  node["amenity"="recycling"]["recycling:electrical_items"="yes"](area.searchArea);
  way["amenity"="recycling"]["recycling:electrical_items"="yes"](area.searchArea);
  relation["amenity"="recycling"]["recycling:electrical_items"="yes"](area.searchArea);
  node["shop"="recycling"]["recycling:electrical_items"="yes"](area.searchArea);
  way["shop"="recycling"]["recycling:electrical_items"="yes"](area.searchArea);
  relation["shop"="recycling"]["recycling:electrical_items"="yes"](area.searchArea);

  node["amenity"="recycling"]["recycling:small_appliances"="yes"](area.searchArea);
  way["amenity"="recycling"]["recycling:small_appliances"="yes"](area.searchArea);
  relation["amenity"="recycling"]["recycling:small_appliances"="yes"](area.searchArea);
  node["shop"="recycling"]["recycling:small_appliances"="yes"](area.searchArea);
  way["shop"="recycling"]["recycling:small_appliances"="yes"](area.searchArea);
  relation["shop"="recycling"]["recycling:small_appliances"="yes"](area.searchArea);

  node["amenity"="recycling"]["recycling:mobile_phones"="yes"](area.searchArea);
  way["amenity"="recycling"]["recycling:mobile_phones"="yes"](area.searchArea);
  relation["amenity"="recycling"]["recycling:mobile_phones"="yes"](area.searchArea);
  node["shop"="recycling"]["recycling:mobile_phones"="yes"](area.searchArea);
  way["shop"="recycling"]["recycling:mobile_phones"="yes"](area.searchArea);
  relation["shop"="recycling"]["recycling:mobile_phones"="yes"](area.searchArea);

  node["amenity"="recycling"]["recycling:cooking_oil"="yes"](area.searchArea);
  way["amenity"="recycling"]["recycling:cooking_oil"="yes"](area.searchArea);
  relation["amenity"="recycling"]["recycling:cooking_oil"="yes"](area.searchArea);
  node["shop"="recycling"]["recycling:cooking_oil"="yes"](area.searchArea);
  way["shop"="recycling"]["recycling:cooking_oil"="yes"](area.searchArea);
  relation["shop"="recycling"]["recycling:cooking_oil"="yes"](area.searchArea);
);
out center tags;
''';

    try {
      final result = await _overpass
          .rawOverpassQL(query: query)
          .timeout(const Duration(seconds: 14));

      Map<String, dynamic>? data;

      if (result is String) {
        data = Map<String, dynamic>.from(jsonDecode(result));
      } else if (result is Map) {
        data = Map<String, dynamic>.from(result);
      }

      final rawElements = data?['elements'];

      if (rawElements is! List) {
        return cache == null
            ? const <PlaceModel>[]
            : List<PlaceModel>.from(cache);
      }

      final elements = List<Map<String, dynamic>>.from(rawElements);

      final pontos = elements
          .where(
            (element) =>
                (element['lat'] != null && element['lon'] != null) ||
                element['center'] != null,
          )
          .map((element) {
            final copy = Map<String, dynamic>.from(element);

            if (copy['lat'] == null || copy['lon'] == null) {
              final center = Map<String, dynamic>.from(copy['center']);
              copy['lat'] = center['lat'];
              copy['lon'] = center['lon'];
            }

            return PlaceModel.fromOverpassMap(copy);
          })
          .where((ponto) => ponto.dentroDoEscopoDoTcc)
          .toList();

      final semDuplicados = _removerDuplicados(pontos);
      _osmCache = semDuplicados;
      _osmCacheAt = DateTime.now();
      return List<PlaceModel>.from(semDuplicados);
    } on TimeoutException {
      return cache == null
          ? const <PlaceModel>[]
          : List<PlaceModel>.from(cache);
    } catch (_) {
      return cache == null
          ? const <PlaceModel>[]
          : List<PlaceModel>.from(cache);
    }
  }

  bool _pontoCorrespondeCategoria(PlaceModel ponto, String categoria) {
    final texto = _normalizar(
      "${ponto.tipo ?? ''} ${ponto.materiaisAceitos.join(' ')}",
    );

    if (categoria.contains('pilha')) {
      return texto.contains('pilha');
    }

    if (categoria.contains('bateria')) {
      return texto.contains('bateria');
    }

    if (categoria.contains('oleo')) {
      return texto.contains('oleo');
    }

    if (categoria.contains('eletron')) {
      return texto.contains('eletron') ||
          texto.contains('celular') ||
          texto.contains('item eletrico') ||
          texto.contains('eletrodomestico');
    }

    return false;
  }

  List<PlaceModel> _removerDuplicados(List<PlaceModel> pontos) {
    final resultado = <PlaceModel>[];
    final distance = Distance();

    for (final ponto in pontos) {
      final nomeNormalizado = _normalizar(ponto.nome);

      final duplicado = resultado.any((existente) {
        if (_normalizar(existente.nome) != nomeNormalizado) {
          return false;
        }

        final distancia = distance.as(
          LengthUnit.Meter,
          LatLng(existente.latitude, existente.longitude),
          LatLng(ponto.latitude, ponto.longitude),
        );

        // Mesma identificação em uma pequena margem cobre diferenças de
        // coordenadas entre uma fonte pública e o cadastro validado sem
        // ocultar filiais diferentes próximas entre si.
        return distancia <= 60;
      });

      if (!duplicado) {
        resultado.add(ponto);
      }
    }

    return resultado;
  }

  String? _detectarCategoria(String texto) {
    final termo = _normalizar(texto);

    if (termo.contains('pilha')) return 'Pilhas';
    if (termo.contains('bateria')) return 'Baterias';

    if (termo.contains('monitor') ||
        termo.contains('eletron') ||
        termo.contains('computador') ||
        termo.contains('celular') ||
        termo.contains('telefone') ||
        termo.contains('eletrodomestico')) {
      return 'Eletrônicos';
    }

    if (termo.contains('oleo') || termo.contains('cozinha')) {
      return 'Óleo';
    }

    if (termo.contains('todos') ||
        termo.contains('ponto de coleta') ||
        termo.contains('coleta sustentavel')) {
      return 'Todos';
    }

    return null;
  }

  String _normalizar(String texto) {
    return texto
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }
}
