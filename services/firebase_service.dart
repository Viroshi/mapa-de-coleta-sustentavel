import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/place_model.dart';
import '../models/suggestion_model.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  bool get isConfigured => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => isConfigured ? _auth.currentUser : null;

  Future<List<PlaceModel>> listarPontosValidados() async {
    if (!isConfigured) return const [];

    try {
      final snapshot = await _db
          .collection('pontos_coleta')
          .where('status', isEqualTo: 'validado')
          .get();

      return snapshot.docs
          .map((doc) => PlaceModel.fromMap(
                {...doc.data(), 'fonte': 'Cadastro validado'},
                id: doc.id,
              ))
          .where((ponto) => ponto.dentroDoEscopoDoTcc)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Stream<List<PlaceModel>> observarTodosOsPontos() {
    if (!isConfigured) return Stream.value(const []);

    return _db.collection('pontos_coleta').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => PlaceModel.fromMap(
                {...doc.data(), 'fonte': 'Cadastro validado'},
                id: doc.id,
              ))
              .toList(),
        );
  }

  Stream<List<SuggestionModel>> observarSugestoesPendentes() {
    if (!isConfigured) return Stream.value(const []);

    return _db
        .collection('sugestoes')
        .where('status', isEqualTo: 'pendente')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SuggestionModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> sugerirPonto(SuggestionModel sugestao) async {
    _ensureConfigured();

    await _db.collection('sugestoes').add({
      ...sugestao.toMap(),
      'status': 'pendente',
      'dataCadastro': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cadastrarPonto(PlaceModel ponto) async {
    _ensureConfigured();

    await _db.collection('pontos_coleta').add({
      ...ponto.toMap(),
      'status': 'validado',
      'dataCadastro': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
      'fonte': 'Cadastro validado',
    });
  }

  Future<void> atualizarPonto(PlaceModel ponto) async {
    _ensureConfigured();
    final id = ponto.id;
    if (id == null || id.isEmpty) {
      throw StateError('Ponto sem identificador para atualização.');
    }

    await _db.collection('pontos_coleta').doc(id).update({
      ...ponto.toMap(),
      'atualizadoEm': FieldValue.serverTimestamp(),
      'fonte': ponto.fonte ?? 'Cadastro validado',
    });
  }

  Future<void> excluirPonto(String id) async {
    _ensureConfigured();
    await _db.collection('pontos_coleta').doc(id).delete();
  }

  Future<void> validarSugestao(SuggestionModel sugestao) async {
    _ensureConfigured();
    final id = sugestao.id;
    if (id == null || id.isEmpty) {
      throw StateError('Sugestão sem identificador.');
    }

    final batch = _db.batch();
    final pontoRef = _db.collection('pontos_coleta').doc();
    final sugestaoRef = _db.collection('sugestoes').doc(id);

    batch.set(pontoRef, {
      'nome': sugestao.nome,
      'descricao': sugestao.descricao,
      'endereco': sugestao.endereco,
      'latitude': sugestao.latitude,
      'longitude': sugestao.longitude,
      'horarioFuncionamento': sugestao.horarioFuncionamento,
      'telefone': sugestao.telefone,
      'materiaisAceitos': sugestao.materiaisAceitos,
      'tipo': sugestao.materiaisAceitos.join(', '),
      'status': 'validado',
      'dataCadastro': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
      'fonte': 'Sugestão validada',
    });

    batch.update(sugestaoRef, {
      'status': 'validado',
      'validadoEm': FieldValue.serverTimestamp(),
      'validadoPor': currentUser?.uid,
    });

    await batch.commit();
  }

  Future<void> rejeitarSugestao(String id) async {
    _ensureConfigured();
    await _db.collection('sugestoes').doc(id).update({
      'status': 'rejeitado',
      'validadoEm': FieldValue.serverTimestamp(),
      'validadoPor': currentUser?.uid,
    });
  }

  Future<bool> entrarComoAdministrador({
    required String email,
    required String senha,
  }) async {
    _ensureConfigured();

    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );

    final user = credential.user;
    if (user == null) return false;

    final doc = await _db.collection('usuarios').doc(user.uid).get();
    final autorizado = _perfilAutorizado(doc.data());

    if (!autorizado) {
      await _auth.signOut();
    }

    return autorizado;
  }

  Future<void> sair() async {
    if (!isConfigured) return;
    await _auth.signOut();
  }

  Future<bool> usuarioAtualEhAdministrador() async {
    if (!isConfigured) return false;
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db.collection('usuarios').doc(user.uid).get();
      return _perfilAutorizado(doc.data());
    } catch (_) {
      return false;
    }
  }

  bool _perfilAutorizado(Map<String, dynamic>? data) {
    final tipo = (data?['tipoUsuario'] ?? data?['tipo_usuario'])
        ?.toString()
        .trim()
        .toLowerCase();

    return tipo == 'administrador' || tipo == 'empresa';
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Firebase ainda não foi configurado neste projeto.',
      );
    }
  }
}
