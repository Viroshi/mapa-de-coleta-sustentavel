class SuggestionModel {
  final String? id;
  final String nome;
  final String descricao;
  final String endereco;
  final double latitude;
  final double longitude;
  final String horarioFuncionamento;
  final String telefone;
  final List<String> materiaisAceitos;
  final String status;
  final String? usuarioId;

  const SuggestionModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.horarioFuncionamento,
    required this.telefone,
    required this.materiaisAceitos,
    this.status = 'pendente',
    this.usuarioId,
  });

  factory SuggestionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final materiais = map['materiaisAceitos'] ?? map['materiais_aceitos'];

    return SuggestionModel(
      id: id ?? map['id']?.toString(),
      nome: map['nome']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      endereco: map['endereco']?.toString() ?? '',
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      horarioFuncionamento: (map['horarioFuncionamento'] ??
              map['horario_funcionamento'])
          ?.toString() ??
          '',
      telefone: map['telefone']?.toString() ?? '',
      materiaisAceitos: materiais is Iterable
          ? materiais.map((item) => item.toString()).toList()
          : const [],
      status: map['status']?.toString() ?? 'pendente',
      usuarioId: (map['usuarioId'] ?? map['id_usuario'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'horarioFuncionamento': horarioFuncionamento,
      'telefone': telefone,
      'materiaisAceitos': materiaisAceitos,
      'status': status,
      if (usuarioId != null) 'usuarioId': usuarioId,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
