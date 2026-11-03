import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_colors.dart';
import '../models/place_model.dart';
import '../models/route_model.dart';
import '../services/location_service.dart';
import '../services/map_launcher_service.dart';
import '../services/collection_point_service.dart';
import '../services/route_service.dart';
import '../widgets/search_bar_widget.dart';

class MapaPage extends StatefulWidget {
  final int refreshToken;

  const MapaPage({super.key, this.refreshToken = 0});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  static const LatLng _teresina = LatLng(-5.0892, -42.8016);

  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final CollectionPointService _service = CollectionPointService();
  final RouteService _routeService = RouteService();
  final LocationService _locationService = LocationService();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _mensagemTimer;

  List<PlaceModel> _lugares = [];
  PlaceModel? _selecionado;
  PlaceModel? _rotaDestino;
  RouteModel? _rotaAtual;

  LatLng? _origem;
  String _origemLabel = 'Localização não definida';
  LatLng? _localizacaoUsuario;
  double? _precisaoUsuario;

  bool _origemSegueUsuario = false;
  bool _localizacaoAtiva = false;
  bool _avisoLocalizacaoAberto = false;

  bool _carregando = false;
  bool _calculandoRota = false;
  bool _buscandoLocalizacao = false;
  int _buscaId = 0;
  String _mensagem = '';
  String _filtroAtivo = 'Todos';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarTodos();
      _mostrarAvisoLocalizacaoSeNecessario();
    });
  }

  @override
  void didUpdateWidget(covariant MapaPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshToken != widget.refreshToken) {
      _recarregarBuscaAtual();
    }
  }

  Future<void> _recarregarBuscaAtual() async {
    final texto = _searchController.text.trim();

    if (texto.isEmpty || _filtroAtivo == 'Todos') {
      await _executarBusca(
        () => _service.buscarTodosEcopontos(),
        filtro: 'Todos',
        moverMapa: false,
      );
      return;
    }

    await _executarBusca(
      () => _service.buscarPorTexto(texto),
      filtro: _filtroAtivo,
      moverMapa: false,
    );
  }

  String get _origemLabelAtual {
    if (_origem == null) {
      return 'Ative sua localização para calcular rotas precisas';
    }

    return _origemLabel;
  }

  bool get _origemDefinida => _origem != null;

  Future<void> _mostrarAvisoLocalizacaoSeNecessario() async {
    if (_avisoLocalizacaoAberto) return;

    final prefs = await SharedPreferences.getInstance();
    final avisoJaVisto = prefs.getBool('location_notice_seen') ?? false;

    if (!mounted || avisoJaVisto || _localizacaoUsuario != null) return;

    _avisoLocalizacaoAberto = true;

    final permitir = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _LocationIntroDialog(),
    );

    _avisoLocalizacaoAberto = false;

    if (!mounted) return;

    await prefs.setBool('location_notice_seen', true);

    if (permitir == true) {
      await _usarMinhaLocalizacao();
    } else {
      setState(() {
        _mensagem = 'Você pode ativar sua localização pelo botão de alvo no mapa.';
      });
      _ocultarMensagemDepois(delay: const Duration(seconds: 6));
    }
  }

  void _ocultarMensagemDepois({Duration delay = const Duration(seconds: 5)}) {
    _mensagemTimer?.cancel();

    if (_mensagem.isEmpty) return;

    _mensagemTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _mensagem = '';
      });
    });
  }

  Future<void> _carregarTodos() async {
    await _executarBusca(
      () => _service.buscarTodosEcopontos(),
      filtro: 'Todos',
      moverMapa: false,
    );
  }

  Future<void> _buscar() async {
    final texto = _searchController.text.trim();

    if (texto.isEmpty) {
      await _carregarTodos();
      return;
    }

    await _executarBusca(
      () => _service.buscarPorTexto(texto),
      filtro: texto,
      moverMapa: true,
    );
  }

  Future<void> _aplicarFiltro(String filtro) async {
    setState(() {
      _filtroAtivo = filtro;
    });

    if (filtro == 'Todos') {
      _searchController.clear();

      await _executarBusca(
        () => _service.buscarTodosEcopontos(),
        filtro: filtro,
        moverMapa: false,
      );

      return;
    }

    _searchController.text = filtro;

    await _executarBusca(
      () => _service.buscarCategoria(filtro),
      filtro: filtro,
      moverMapa: true,
    );
  }

  Future<void> _executarBusca(
    Future<List<PlaceModel>> Function() action, {
    required String filtro,
    required bool moverMapa,
  }) async {
    final buscaId = ++_buscaId;

    setState(() {
      _carregando = true;
      _mensagem = '';
    });

    final resultados = _ordenarPorDistanciaDaOrigem(await action());

    if (!mounted || buscaId != _buscaId) return;

    setState(() {
      _lugares = resultados;
      _selecionado = resultados.isNotEmpty ? resultados.first : null;
      _rotaAtual = null;
      _rotaDestino = null;
      _carregando = false;
      _filtroAtivo = filtro.isEmpty ? 'Todos' : filtro;
      _mensagem = resultados.isEmpty
          ? 'Nenhum ponto encontrado.'
          : _origemDefinida
              ? 'Pontos atualizados e ordenados pela proximidade da sua localização.'
              : '';
    });

    _ocultarMensagemDepois();

    if (resultados.isNotEmpty) {
      _minimizarPainel();
    }

    if (resultados.isNotEmpty && moverMapa) {
      final primeiro = resultados.first;

      _mapController.move(
        LatLng(primeiro.latitude, primeiro.longitude),
        15,
      );
    }
  }

  List<PlaceModel> _ordenarPorDistanciaDaOrigem(List<PlaceModel> pontos) {
    final origem = _origem;

    if (origem == null) {
      return [...pontos];
    }

    final distance = Distance();
    final ordenados = [...pontos];

    ordenados.sort((a, b) {
      final distanciaA = distance.as(
        LengthUnit.Meter,
        origem,
        LatLng(a.latitude, a.longitude),
      );
      final distanciaB = distance.as(
        LengthUnit.Meter,
        origem,
        LatLng(b.latitude, b.longitude),
      );
      return distanciaA.compareTo(distanciaB);
    });

    return ordenados;
  }

  void _moverPainel(double tamanho) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sheetController.isAttached) return;

      _sheetController.animateTo(
        tamanho,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _expandirPainel() {
    _moverPainel(0.46);
  }

  void _minimizarPainel() {
    _moverPainel(0.15);
  }

  void _selecionarLugar(PlaceModel lugar) {
    setState(() {
      _selecionado = lugar;
      if (_rotaDestino != lugar) {
        _rotaAtual = null;
        _rotaDestino = null;
      }
    });

    _mapController.move(
      LatLng(lugar.latitude, lugar.longitude),
      16,
    );

    _expandirPainel();
  }

  void _limparRota() {
    setState(() {
      _rotaAtual = null;
      _rotaDestino = null;
      _mensagem = 'Rota removida.';
    });
    _ocultarMensagemDepois();
  }

  Future<bool> _usarMinhaLocalizacao() async {
    setState(() {
      _buscandoLocalizacao = true;
      _mensagem = 'Buscando sua localização...';
    });

    final acesso = await _locationService.ensurePermission();

    if (!mounted) return false;

    if (!acesso.granted) {
      setState(() {
        _buscandoLocalizacao = false;
        _mensagem = acesso.message;
      });
      _ocultarMensagemDepois(delay: const Duration(seconds: 6));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(acesso.message),
          action: acesso.serviceDisabled
              ? SnackBarAction(
                  label: 'Ativar GPS',
                  onPressed: _locationService.openLocationSettings,
                )
              : SnackBarAction(
                  label: 'Config.',
                  onPressed: _locationService.openAppSettings,
                ),
        ),
      );

      return false;
    }

    try {
      final posicaoAtual = await _locationService.getCurrentPosition();

      if (!mounted) return false;

      _atualizarLocalizacaoUsuario(
        posicaoAtual,
        centralizar: true,
        usarComoOrigem: true,
        mostrarMensagem: true,
      );

      _iniciarRastreamento();
      return true;
    } catch (_) {
      if (!mounted) return false;

      setState(() {
        _buscandoLocalizacao = false;
        _mensagem = 'Não foi possível obter sua localização agora.';
      });
      _ocultarMensagemDepois();
      return false;
    }
  }

  void _iniciarRastreamento() {
    _positionSubscription?.cancel();

    _positionSubscription = _locationService.getPositionStream().listen(
      (posicao) {
        if (!mounted) return;

        _atualizarLocalizacaoUsuario(
          posicao,
          usarComoOrigem: _origemSegueUsuario,
        );
      },
      onError: (_) {
        if (!mounted) return;

        setState(() {
          _localizacaoAtiva = false;
          _origemSegueUsuario = false;
          _buscandoLocalizacao = false;
          _mensagem = 'O acompanhamento da localização foi interrompido.';
        });
        _ocultarMensagemDepois();
      },
    );
  }

  void _atualizarLocalizacaoUsuario(
    Position posicao, {
    bool centralizar = false,
    bool usarComoOrigem = false,
    bool mostrarMensagem = false,
  }) {
    final novaLocalizacao = LatLng(
      posicao.latitude,
      posicao.longitude,
    );

    final origemAnterior = _origem;
    final mudouBem = origemAnterior != null &&
        Distance().as(
              LengthUnit.Meter,
              origemAnterior,
              novaLocalizacao,
            ) >=
            25;

    setState(() {
      _localizacaoUsuario = novaLocalizacao;
      _precisaoUsuario = posicao.accuracy;
      _localizacaoAtiva = true;
      _buscandoLocalizacao = false;

      if (usarComoOrigem || _origemSegueUsuario) {
        _origem = novaLocalizacao;
        _origemLabel = 'Minha localização em tempo real';
        _origemSegueUsuario = true;
        _lugares = _ordenarPorDistanciaDaOrigem(_lugares);

        if (_rotaAtual != null && mudouBem) {
          _rotaAtual = null;
          _rotaDestino = null;
          _mensagem = 'Sua posição mudou. Toque em Traçar rota para atualizar o caminho.';
        } else if (mostrarMensagem) {
          _mensagem = 'Localização ativa. Suas rotas agora usam sua posição atual.';
        }
      } else if (mostrarMensagem) {
        _mensagem = 'Localização encontrada.';
      }
    });

    if (mostrarMensagem || mudouBem) {
      _ocultarMensagemDepois(delay: const Duration(seconds: 6));
    }

    if (centralizar) {
      _mapController.move(novaLocalizacao, 16);
    }
  }

  void _centralizarNaMinhaLocalizacao() {
    final localizacao = _localizacaoUsuario;

    if (localizacao == null || !_localizacaoAtiva) {
      _usarMinhaLocalizacao();
      return;
    }

    setState(() {
      _rotaAtual = null;
      _rotaDestino = null;
      _origem = localizacao;
      _origemLabel = 'Minha localização em tempo real';
      _origemSegueUsuario = true;
      _mensagem = 'Mapa centralizado na sua localização.';
    });
    _ocultarMensagemDepois();

    _mapController.move(localizacao, 16);
  }

  void _pausarLocalizacaoTempoReal() {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    setState(() {
      _localizacaoAtiva = false;
      _origemSegueUsuario = false;
      _mensagem = 'Localização em tempo real pausada.';
    });
    _ocultarMensagemDepois();
  }

  Future<void> _tracarRota(PlaceModel lugar) async {
    if (_origem == null) {
      setState(() {
        _selecionado = lugar;
        _mensagem = 'Ative sua localização para calcular a rota dentro do app.';
      });
      _ocultarMensagemDepois(delay: const Duration(seconds: 6));

      final localizacaoAtivada = await _usarMinhaLocalizacao();

      if (!localizacaoAtivada || _origem == null) {
        return;
      }
    }

    final origem = _origem!;
    final destino = LatLng(lugar.latitude, lugar.longitude);

    setState(() {
      _selecionado = lugar;
      _rotaDestino = lugar;
      _rotaAtual = null;
      _calculandoRota = true;
      _mensagem = 'Calculando rota a partir de $_origemLabel...';
    });

    final rota = await _routeService.buscarRota(
      origem: origem,
      destino: destino,
    );

    if (!mounted) return;

    if (rota == null) {
      setState(() {
        _calculandoRota = false;
        _mensagem = 'Não foi possível calcular a rota agora.';
      });
      _ocultarMensagemDepois();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tente novamente ou use Abrir navegação.'),
        ),
      );

      return;
    }

    setState(() {
      _rotaAtual = rota;
      _calculandoRota = false;
      _mensagem = 'Rota pronta: ${rota.distanciaFormatada} • ${rota.duracaoFormatada}.';
    });
    _ocultarMensagemDepois();

    _focarRota(rota.origem, rota.destino);
  }

  void _focarRota(LatLng origem, LatLng destino) {
    final centro = LatLng(
      (origem.latitude + destino.latitude) / 2,
      (origem.longitude + destino.longitude) / 2,
    );

    final distanciaKm = Distance().as(
      LengthUnit.Kilometer,
      origem,
      destino,
    );

    final zoom = distanciaKm < 1.5
        ? 15.0
        : distanciaKm < 4
            ? 14.0
            : distanciaKm < 9
                ? 13.0
                : 12.0;

    _mapController.move(centro, zoom);
  }

  Future<void> _abrirNavegacaoExterna(PlaceModel lugar) async {
    _mapController.move(
      LatLng(lugar.latitude, lugar.longitude),
      17,
    );

    final origem = _origem;
    final usarOrigemNoMapaExterno = origem != null &&
        (_origemSegueUsuario ||
            _origemLabel == 'Ponto escolhido no mapa' ||
            _origemLabel == 'Centro visível do mapa');

    final abriu = await MapLauncherService.abrirRotas(
      latitude: lugar.latitude,
      longitude: lugar.longitude,
      nome: lugar.nome,
      originLatitude: usarOrigemNoMapaExterno ? origem.latitude : null,
      originLongitude: usarOrigemNoMapaExterno ? origem.longitude : null,
    );

    if (!mounted) return;

    if (!abriu) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o aplicativo de mapas.'),
        ),
      );
    }
  }

  void _mostrarDetalhes(PlaceModel lugar) {
    final rota = _rotaDestino == lugar ? _rotaAtual : null;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _PlaceDetailsSheet(
          lugar: lugar,
          rota: rota,
          origemLabel: _origemLabelAtual,
          onTraceRoute: () {
            Navigator.of(context).pop();
            _tracarRota(lugar);
          },
          onOpenExternal: () {
            Navigator.of(context).pop();
            _abrirNavegacaoExterna(lugar);
          },
        );
      },
    );
  }

  List<Marker> _buildMarkers() {
    final markers = _lugares.map((lugar) {
      return Marker(
        point: LatLng(lugar.latitude, lugar.longitude),
        width: 54,
        height: 54,
        child: GestureDetector(
          onTap: () => _selecionarLugar(lugar),
          child: Tooltip(
            message: lugar.nome,
            child: _MapPin(
              icon: _iconeParaLugar(lugar),
              color: _corParaLugar(lugar),
            ),
          ),
        ),
      );
    }).toList();

    final localizacaoUsuario = _localizacaoUsuario;

    if (localizacaoUsuario != null) {
      markers.add(
        Marker(
          point: localizacaoUsuario,
          width: 66,
          height: 66,
          child: Tooltip(
            message: _precisaoUsuario == null
                ? 'Minha localização'
                : 'Minha localização • precisão de ${_precisaoUsuario!.round()} m',
            child: _UserLocationPin(
              accuracy: _precisaoUsuario,
              isOrigin: _origemSegueUsuario,
            ),
          ),
        ),
      );
    }

    final origem = _origem;

    if (origem != null && !_origemSegueUsuario) {
      markers.add(
        Marker(
          point: origem,
          width: 52,
          height: 52,
          child: Tooltip(
            message: 'Origem: $_origemLabel',
            child: const _OriginPin(),
          ),
        ),
      );
    }

    return markers;
  }

  IconData _iconeParaLugar(PlaceModel lugar) {
    final texto = '${lugar.nome} ${lugar.tipo ?? ''}'.toLowerCase();

    if (texto.contains('óleo') || texto.contains('oleo')) {
      return Icons.water_drop;
    }

    if (texto.contains('battery') ||
        texto.contains('bateria') ||
        texto.contains('pilha')) {
      return Icons.battery_charging_full;
    }

    if (texto.contains('eletr') ||
        texto.contains('monitor') ||
        texto.contains('computer') ||
        texto.contains('celular')) {
      return Icons.devices;
    }

    return Icons.recycling;
  }

  Color _corParaLugar(PlaceModel lugar) {
    final texto = '${lugar.nome} ${lugar.tipo ?? ''}'.toLowerCase();

    if (texto.contains('óleo') || texto.contains('oleo')) {
      return AppColors.tertiary;
    }

    if (texto.contains('battery') ||
        texto.contains('bateria') ||
        texto.contains('pilha')) {
      return AppColors.warning;
    }

    if (texto.contains('eletr') ||
        texto.contains('monitor') ||
        texto.contains('computer') ||
        texto.contains('celular')) {
      return AppColors.secondary;
    }

    return AppColors.primary;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mensagemTimer?.cancel();
    _sheetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selecionado = _selecionado;
    final rotaDoSelecionado = _rotaDestino == selecionado ? _rotaAtual : null;
    final calculandoSelecionado =
        _calculandoRota && selecionado != null && _rotaDestino == selecionado;
    final largura = MediaQuery.sizeOf(context).width;
    final isCompact = largura < 390;
    final mapButtonTop = isCompact ? 190.0 : 178.0;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _teresina,
            initialZoom: 13,
            onTap: (_, _) {
              FocusScope.of(context).unfocus();
              _minimizarPainel();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mdlxe',
            ),
            if (_rotaAtual != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _rotaAtual!.pontos,
                    color: AppColors.secondary,
                    strokeWidth: 6,
                    borderColor: Colors.white.withValues(alpha: 0.9),
                    borderStrokeWidth: 3,
                  ),
                ],
              ),
            MarkerLayer(
              markers: _buildMarkers(),
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchBarWidget(
                controller: _searchController,
                onSearch: _buscar,
                filtroAtivo: _filtroAtivo,
                carregando: _carregando,
                onFilterSelected: _aplicarFiltro,
              ),
            ),
          ),
        ),
        Positioned(
          top: mapButtonTop,
          right: isCompact ? 10 : 14,
          child: SafeArea(
            child: Column(
              children: [
                _FloatingMapButton(
                  tooltip: _localizacaoUsuario == null
                      ? 'Usar minha localização'
                      : 'Centralizar na minha localização',
                  icon: _buscandoLocalizacao
                      ? Icons.hourglass_top
                      : _localizacaoAtiva
                          ? Icons.gps_fixed
                          : Icons.my_location,
                  onPressed: _buscandoLocalizacao
                      ? null
                      : _localizacaoUsuario == null
                          ? _usarMinhaLocalizacao
                          : _centralizarNaMinhaLocalizacao,
                ),
                if (_localizacaoAtiva) ...[
                  const SizedBox(height: 10),
                  _FloatingMapButton(
                    tooltip: 'Pausar localização em tempo real',
                    icon: Icons.gps_off,
                    onPressed: _pausarLocalizacaoTempoReal,
                  ),
                ],
                if (_rotaAtual != null) ...[
                  const SizedBox(height: 10),
                  _FloatingMapButton(
                    tooltip: 'Limpar rota',
                    icon: Icons.close,
                    onPressed: _limparRota,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_mensagem.isNotEmpty)
          Positioned(
            top: isCompact ? 144 : 148,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _MapStatusPill(
                  key: ValueKey(_mensagem),
                  mensagem: _mensagem,
                ),
              ),
            ),
          ),
        if (selecionado != null)
          _CollectionPointDraggableSheet(
            controller: _sheetController,
            lugar: selecionado,
            rota: rotaDoSelecionado,
            origemLabel: _origemLabelAtual,
            origemDefinida: _origemDefinida,
            calculandoRota: calculandoSelecionado,
            onTraceRoute: () => _tracarRota(selecionado),
            onOpenExternal: () => _abrirNavegacaoExterna(selecionado),
            onDetails: () => _mostrarDetalhes(selecionado),
          ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MapPin({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Icon(
                icon,
                color: Colors.white,
                size: 19,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 14,
          height: 5,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _OriginPin extends StatelessWidget {
  const _OriginPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.onSurface,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        Icons.trip_origin,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}


class _UserLocationPin extends StatelessWidget {
  final double? accuracy;
  final bool isOrigin;

  const _UserLocationPin({
    required this.accuracy,
    required this.isOrigin,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isOrigin ? Icons.my_location : Icons.person_pin_circle,
            color: Colors.white,
            size: 17,
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: isOrigin ? AppColors.secondary : AppColors.onSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isOrigin ? 'Você' : 'Local',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _LocationIntroDialog extends StatelessWidget {
  const _LocationIntroDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.my_location,
          color: AppColors.primary,
        ),
      ),
      title: const Text('Usar sua localização?'),
      content: const Text(
        'O Mapa de Coleta Sustentável usa sua localização, quando autorizada, para ordenar os pontos mais próximos e calcular rotas. Se a permissão for negada, ela poderá ser ativada depois nas configurações do aplicativo.',
        style: TextStyle(height: 1.35),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Agora não'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.location_searching),
          label: const Text('Permitir localização'),
        ),
      ],
    );
  }
}


class _MapStatusPill extends StatelessWidget {
  final String mensagem;

  const _MapStatusPill({
    super.key,
    required this.mensagem,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            mensagem,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionPointDraggableSheet extends StatelessWidget {
  final DraggableScrollableController controller;
  final PlaceModel lugar;
  final RouteModel? rota;
  final String origemLabel;
  final bool origemDefinida;
  final bool calculandoRota;
  final VoidCallback onTraceRoute;
  final VoidCallback onOpenExternal;
  final VoidCallback onDetails;

  const _CollectionPointDraggableSheet({
    required this.controller,
    required this.lugar,
    required this.rota,
    required this.origemLabel,
    required this.origemDefinida,
    required this.calculandoRota,
    required this.onTraceRoute,
    required this.onOpenExternal,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.sizeOf(context).height;
    final compacto = altura < 720;
    final minSize = compacto ? 0.14 : 0.12;
    final initialSize = compacto ? 0.18 : 0.16;
    final midSize = compacto ? 0.50 : 0.46;
    final maxSize = compacto ? 0.82 : 0.74;

    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          controller: controller,
          expand: false,
          snap: true,
          minChildSize: minSize,
          initialChildSize: initialSize,
          maxChildSize: maxSize,
          snapSizes: [minSize, initialSize, midSize, maxSize],
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: _CollectionPointCard(
                      lugar: lugar,
                      rota: rota,
                      origemLabel: origemLabel,
                      origemDefinida: origemDefinida,
                      calculandoRota: calculandoRota,
                      onTraceRoute: onTraceRoute,
                      onOpenExternal: onOpenExternal,
                      onDetails: onDetails,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _FloatingMapButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest.withValues(alpha: 0.96),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 46,
        height: 46,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 22,
          icon: Icon(icon),
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _CollectionPointCard extends StatelessWidget {
  final PlaceModel lugar;
  final RouteModel? rota;
  final String origemLabel;
  final bool origemDefinida;
  final bool calculandoRota;
  final VoidCallback onTraceRoute;
  final VoidCallback onOpenExternal;
  final VoidCallback onDetails;

  const _CollectionPointCard({
    required this.lugar,
    required this.rota,
    required this.origemLabel,
    required this.origemDefinida,
    required this.calculandoRota,
    required this.onTraceRoute,
    required this.onOpenExternal,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final endereco = lugar.endereco ??
        'Lat: ${lugar.latitude.toStringAsFixed(5)}, Lon: ${lugar.longitude.toStringAsFixed(5)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lugar.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lugar.tipo ?? 'Ponto de coleta',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: lugar.demonstrativo
                      ? AppColors.warningContainer
                      : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lugar.demonstrativo ? 'Base local' : (lugar.capacidade ?? 'Coleta'),
                  style: TextStyle(
                    color: lugar.demonstrativo
                        ? AppColors.warning
                        : AppColors.onPrimaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              endereco,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Origem: $origemLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (lugar.materiaisAceitos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: lugar.materiaisAceitos.take(4).map((material) {
                  return _MaterialChip(label: material);
                }).toList(),
              ),
            ),
          ],
          if (rota != null) ...[
            const SizedBox(height: 12),
            _RouteSummary(rota: rota!),
          ],
          if (calculandoRota) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 5),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: calculandoRota ? null : onTraceRoute,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: Icon(
                    origemDefinida ? Icons.alt_route : Icons.my_location,
                    size: 18,
                  ),
                  label: Text(
                    calculandoRota
                        ? 'Calculando'
                        : origemDefinida
                            ? 'Rota no app'
                            : 'Usar localização',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onOpenExternal,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.navigation_outlined, size: 18),
                  label: const Text('Iniciar'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Detalhes',
                onPressed: onDetails,
                icon: const Icon(Icons.info_outline),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceDetailsSheet extends StatelessWidget {
  final PlaceModel lugar;
  final RouteModel? rota;
  final String origemLabel;
  final VoidCallback onTraceRoute;
  final VoidCallback onOpenExternal;

  const _PlaceDetailsSheet({
    required this.lugar,
    required this.rota,
    required this.origemLabel,
    required this.onTraceRoute,
    required this.onOpenExternal,
  });

  @override
  Widget build(BuildContext context) {
    final endereco = lugar.endereco ??
        'Lat: ${lugar.latitude.toStringAsFixed(5)}, Lon: ${lugar.longitude.toStringAsFixed(5)}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lugar.nome,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lugar.tipo ?? 'Ponto de coleta',
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.place_outlined,
              label: 'Localização',
              value: endereco,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.trip_origin,
              label: 'Origem da rota',
              value: origemLabel,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.schedule_outlined,
              label: 'Horário de funcionamento',
              value: lugar.horarioFuncionamento?.trim().isNotEmpty == true
                  ? lugar.horarioFuncionamento!
                  : 'Não informado',
            ),
            if (rota != null) ...[
              const SizedBox(height: 16),
              _RouteSummary(rota: rota!),
            ],
            if (lugar.materiaisAceitos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Materiais aceitos',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: lugar.materiaisAceitos
                    .map((material) => _MaterialChip(label: material))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Contato',
              value: lugar.telefone?.trim().isNotEmpty == true
                  ? lugar.telefone!
                  : 'Não informado',
            ),
            if ((lugar.descricao ?? lugar.observacao)?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 16),
              _DetailRow(
                icon: Icons.description_outlined,
                label: 'Descrição',
                value: (lugar.descricao ?? lugar.observacao)!,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onTraceRoute,
                    icon: const Icon(Icons.alt_route),
                    label: const Text('Traçar no app'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onOpenExternal,
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Iniciar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  final RouteModel rota;

  const _RouteSummary({required this.rota});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryFixed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.alt_route, color: AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${rota.distanciaFormatada} até o ponto • ${rota.duracaoFormatada}',
              style: const TextStyle(
                color: AppColors.onSecondaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MaterialChip extends StatelessWidget {
  final String label;

  const _MaterialChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
