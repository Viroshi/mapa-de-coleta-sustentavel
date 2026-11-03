class PlaceModel {
  final String? id;
  final String nome;
  final double latitude;
  final double longitude;
  final String? tipo;
  final String? descricao;
  final String? endereco;
  final String? horarioFuncionamento;
  final String? telefone;
  final List<String> materiaisAceitos;
  final String status;

  // Campos mantidos por compatibilidade com a base local já existente.
  final String? capacidade;
  final bool demonstrativo;
  final String? observacao;
  final String? fonte;
  final String? atualizadoEm;

  const PlaceModel({
    this.id,
    required this.nome,
    required this.latitude,
    required this.longitude,
    this.tipo,
    this.descricao,
    this.endereco,
    this.horarioFuncionamento,
    this.telefone,
    this.materiaisAceitos = const [],
    this.status = 'validado',
    this.capacidade,
    this.demonstrativo = false,
    this.observacao,
    this.fonte,
    this.atualizadoEm,
  });

  factory PlaceModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final materiais = map['materiaisAceitos'] ?? map['materiais_aceitos'];

    return PlaceModel(
      id: id ?? map['id']?.toString(),
      nome: map['nome']?.toString() ?? 'Ponto de coleta',
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      tipo: map['tipo']?.toString(),
      descricao: map['descricao']?.toString(),
      endereco: map['endereco']?.toString(),
      horarioFuncionamento: (map['horarioFuncionamento'] ??
              map['horario_funcionamento'])
          ?.toString(),
      telefone: map['telefone']?.toString(),
      materiaisAceitos: materiais is Iterable
          ? materiais.map((item) => item.toString()).toList()
          : const [],
      status: map['status']?.toString() ?? 'validado',
      capacidade: map['capacidade']?.toString(),
      observacao: map['observacao']?.toString(),
      fonte: map['fonte']?.toString(),
      atualizadoEm: map['atualizadoEm']?.toString(),
    );
  }

  factory PlaceModel.fromOverpassMap(Map<String, dynamic> map) {
    final tags = Map<String, dynamic>.from(map['tags'] ?? {});

    final nome = tags['name']?.toString() ??
        tags['operator']?.toString() ??
        'Ponto de coleta';

    final tipo = tags['amenity']?.toString() ??
        tags['shop']?.toString() ??
        tags['recycling_type']?.toString();

    return PlaceModel(
      nome: nome,
      latitude: _toDouble(map['lat']),
      longitude: _toDouble(map['lon']),
      tipo: _tipoLegivel(tags, tipo),
      descricao: tags['description']?.toString(),
      endereco: _montarEndereco(tags),
      horarioFuncionamento: tags['opening_hours']?.toString(),
      telefone: tags['phone']?.toString() ?? tags['contact:phone']?.toString(),
      capacidade: _capacidade(tags),
      materiaisAceitos: _materiais(tags),
      observacao: tags['description']?.toString(),
      fonte: 'OpenStreetMap',
      status: 'validado',
    );
  }

  factory PlaceModel.fromSearchAddressMap(Map<String, dynamic> map) {
    return PlaceModel(
      nome: map['display_name']?.toString() ?? 'Endereço encontrado',
      latitude: double.tryParse(map['lat'].toString()) ?? 0.0,
      longitude: double.tryParse(map['lon'].toString()) ?? 0.0,
      tipo: 'Endereço',
      endereco: map['display_name']?.toString(),
      capacidade: 'Referência',
      descricao:
          'Endereço de referência para auxiliar a navegação no mapa.',
      observacao:
          'Endereço de referência para auxiliar a navegação no mapa.',
      fonte: 'Busca de endereço',
      status: 'validado',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao ?? observacao ?? '',
      'endereco': endereco ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'horarioFuncionamento': horarioFuncionamento ?? '',
      'telefone': telefone ?? '',
      'tipo': tipo ?? '',
      'materiaisAceitos': materiaisAceitos,
      'status': status,
    };
  }

  PlaceModel copyWith({
    String? id,
    String? nome,
    double? latitude,
    double? longitude,
    String? tipo,
    String? descricao,
    String? endereco,
    String? horarioFuncionamento,
    String? telefone,
    List<String>? materiaisAceitos,
    String? status,
  }) {
    return PlaceModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tipo: tipo ?? this.tipo,
      descricao: descricao ?? this.descricao,
      endereco: endereco ?? this.endereco,
      horarioFuncionamento:
          horarioFuncionamento ?? this.horarioFuncionamento,
      telefone: telefone ?? this.telefone,
      materiaisAceitos: materiaisAceitos ?? this.materiaisAceitos,
      status: status ?? this.status,
      capacidade: capacidade,
      demonstrativo: demonstrativo,
      observacao: observacao,
      fonte: fonte,
      atualizadoEm: atualizadoEm,
    );
  }

  bool contemTexto(String termo) {
    final alvo = [
      nome,
      tipo,
      descricao,
      endereco,
      horarioFuncionamento,
      capacidade,
      observacao,
      fonte,
      telefone,
      atualizadoEm,
      ...materiaisAceitos,
    ].whereType<String>().join(' ').toLowerCase();

    return alvo.contains(termo.toLowerCase());
  }

  bool get dentroDoEscopoDoTcc {
    final texto = [tipo, ...materiaisAceitos]
        .whereType<String>()
        .join(' ')
        .toLowerCase();

    return texto.contains('eletr') ||
        texto.contains('celular') ||
        texto.contains('pilha') ||
        texto.contains('bateria') ||
        texto.contains('óleo') ||
        texto.contains('oleo');
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static String? _montarEndereco(Map<String, dynamic> tags) {
    final rua = tags['addr:street']?.toString();
    final numero = tags['addr:housenumber']?.toString();
    final bairro = tags['addr:suburb']?.toString();
    final cidade = tags['addr:city']?.toString();

    final partes = <String>[];

    if (rua != null && rua.isNotEmpty) {
      partes.add(numero != null && numero.isNotEmpty ? '$rua, $numero' : rua);
    }

    if (bairro != null && bairro.isNotEmpty) {
      partes.add(bairro);
    }

    if (cidade != null && cidade.isNotEmpty) {
      partes.add(cidade);
    }

    if (partes.isEmpty) return null;

    return partes.join(' - ');
  }

  static String? _capacidade(Map<String, dynamic> tags) {
    final recyclingType = tags['recycling_type']?.toString();

    if (recyclingType == 'centre') {
      return 'Centro de coleta';
    }

    if (recyclingType == 'container') {
      return 'Ponto de entrega';
    }

    return 'Ponto de coleta';
  }

  static String? _tipoLegivel(Map<String, dynamic> tags, String? tipo) {
    if (tags['recycling:batteries'] == 'yes') {
      return 'Pilhas e baterias';
    }

    if (tags['recycling:mobile_phones'] == 'yes') {
      return 'Eletrônicos';
    }

    if (tags['recycling:electronics'] == 'yes' ||
        tags['recycling:electrical_items'] == 'yes' ||
        tags['recycling:small_appliances'] == 'yes') {
      return 'Eletrônicos';
    }

    if (tags['recycling:cooking_oil'] == 'yes') {
      return 'Óleo de cozinha';
    }

    if (tipo == 'recycling') {
      return 'Ponto de coleta';
    }

    return tipo;
  }

  static List<String> _materiais(Map<String, dynamic> tags) {
    final materiais = <String>[];

    void adicionar(String chave, String nome) {
      if (tags[chave] == 'yes') {
        materiais.add(nome);
      }
    }

    adicionar('recycling:batteries', 'Pilhas e baterias');
    adicionar('recycling:mobile_phones', 'Celulares');
    adicionar('recycling:electronics', 'Eletrônicos');
    adicionar('recycling:electrical_items', 'Itens elétricos');
    adicionar('recycling:small_appliances', 'Pequenos eletrodomésticos');
    adicionar('recycling:cooking_oil', 'Óleo de cozinha');

    return materiais;
  }
}
