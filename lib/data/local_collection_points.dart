import '../models/place_model.dart';

class LocalCollectionPoints {
  LocalCollectionPoints._();

  static const _fonteTre = 'TRE-PI / Projeto TRECiclar';
  static const _fonteAguas = 'Águas de Teresina / divulgação pública';
  static const _atualizadoEm = 'Base revisada em junho de 2026';

  /// Base pública revisada que complementa os dados do Firebase e do
  /// OpenStreetMap. Contém apenas os tipos de resíduos previstos no TCC.
  static const List<PlaceModel> todos = [
    PlaceModel(
      nome: 'Pão de Açúcar - Jóquei Clube',
      latitude: -5.069827,
      longitude: -42.783285,
      tipo: 'Eletrônicos',
      endereco:
          'Av. Dom Severino com Rua Homero Castelo Branco - Jóquei Clube, Teresina - PI',
      materiaisAceitos: ['Celulares'],
      descricao: 'Ponto indicado para descarte de aparelhos celulares.',
      fonte: _fonteTre,
      atualizadoEm: _atualizadoEm,
    ),
    PlaceModel(
      nome: 'TIM - Av. Frei Serafim',
      latitude: -5.08700,
      longitude: -42.80371,
      tipo: 'Eletrônicos e baterias',
      endereco: 'Av. Frei Serafim, 1989 - Centro, Teresina - PI',
      materiaisAceitos: ['Celulares', 'Baterias'],
      descricao: 'Ponto indicado para descarte de celulares e baterias.',
      telefone: '(86) 3215-3300',
      fonte: _fonteTre,
      atualizadoEm: _atualizadoEm,
    ),
    PlaceModel(
      nome: 'Vivo - Av. Frei Serafim',
      latitude: -5.08652,
      longitude: -42.80379,
      tipo: 'Eletrônicos e baterias',
      endereco: 'Av. Frei Serafim, 2439 - Centro, Teresina - PI',
      materiaisAceitos: ['Celulares', 'Baterias'],
      descricao: 'Ponto indicado para descarte de celulares e baterias.',
      fonte: _fonteTre,
      atualizadoEm: _atualizadoEm,
    ),
    PlaceModel(
      nome: 'Vivo - Riverside Walk Shopping',
      latitude: -5.078676,
      longitude: -42.795053,
      tipo: 'Eletrônicos e baterias',
      endereco:
          'Riverside Walk Shopping, Praça do Caribe - Jóquei Clube, Teresina - PI',
      materiaisAceitos: ['Celulares', 'Baterias'],
      descricao: 'Ponto indicado para descarte de celulares e baterias.',
      fonte: _fonteTre,
      atualizadoEm: _atualizadoEm,
    ),
    PlaceModel(
      nome: 'Santander - Av. João XXIII / Posto King',
      latitude: -5.080268,
      longitude: -42.791319,
      tipo: 'Pilhas e baterias',
      endereco: 'Av. João XXIII, Posto King - Fátima, Teresina - PI',
      materiaisAceitos: ['Pilhas', 'Baterias'],
      descricao: 'Ponto indicado para descarte de pilhas e baterias.',
      fonte: _fonteTre,
      atualizadoEm: _atualizadoEm,
    ),
    PlaceModel(
      nome: 'Águas de Teresina - ETA Sul',
      latitude: -5.14120,
      longitude: -42.80440,
      tipo: 'Óleo, pilhas e baterias',
      endereco: 'Rua D, 555a - Distrito Industrial, Teresina - PI',
      materiaisAceitos: ['Óleo de cozinha', 'Pilhas', 'Baterias'],
      descricao:
          'Ponto divulgado para descarte de óleo de cozinha, pilhas e baterias.',
      fonte: _fonteAguas,
      atualizadoEm: _atualizadoEm,
    ),
    PlaceModel(
      nome: 'Águas de Teresina - Loja Parque Piauí',
      latitude: -5.14510,
      longitude: -42.78830,
      tipo: 'Óleo, pilhas e baterias',
      endereco:
          'Av. Prefeito Wall Ferraz (BR-316), 9832 - Parque Piauí, Teresina - PI',
      materiaisAceitos: ['Óleo de cozinha', 'Pilhas', 'Baterias'],
      descricao:
          'Ponto divulgado para descarte de óleo de cozinha, pilhas e baterias.',
      fonte: _fonteAguas,
      atualizadoEm: _atualizadoEm,
    ),
    PlaceModel(
      nome: 'Águas de Teresina - ETE Leste',
      latitude: -5.07680,
      longitude: -42.79390,
      tipo: 'Óleo, pilhas e baterias',
      endereco:
          'Rua Des. Adalberto Correia Lima, s/n - Ininga, Teresina - PI',
      materiaisAceitos: ['Óleo de cozinha', 'Pilhas', 'Baterias'],
      descricao:
          'Ponto divulgado para descarte de óleo de cozinha, pilhas e baterias.',
      fonte: _fonteAguas,
      atualizadoEm: _atualizadoEm,
    ),
    PlaceModel(
      nome: 'Águas de Teresina - Sede',
      latitude: -5.08460,
      longitude: -42.73890,
      tipo: 'Óleo, pilhas e baterias',
      endereco:
          'Av. Professor Camilo Filho, 1960 - Todos os Santos, Teresina - PI',
      materiaisAceitos: ['Óleo de cozinha', 'Pilhas', 'Baterias'],
      descricao:
          'Ponto divulgado para descarte de óleo de cozinha, pilhas e baterias.',
      fonte: _fonteAguas,
      atualizadoEm: _atualizadoEm,
    ),
  ];
}
