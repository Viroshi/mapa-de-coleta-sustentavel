import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models/place_model.dart';
import '../models/suggestion_model.dart';
import '../services/firebase_service.dart';
import '../widgets/collection_point_form.dart';

class SuggestPointPage extends StatefulWidget {
  const SuggestPointPage({super.key});

  @override
  State<SuggestPointPage> createState() => _SuggestPointPageState();
}

class _SuggestPointPageState extends State<SuggestPointPage> {
  int _formVersion = 0;
  bool _sent = false;

  Future<void> _submit(PlaceModel point) async {
    final service = FirebaseService.instance;
    if (!service.isConfigured) {
      throw StateError(
        'O Firebase precisa ser configurado para enviar sugestões ao sistema.',
      );
    }

    await service.sugerirPonto(
      SuggestionModel(
        nome: point.nome,
        descricao: point.descricao ?? '',
        endereco: point.endereco ?? '',
        latitude: point.latitude,
        longitude: point.longitude,
        horarioFuncionamento: point.horarioFuncionamento ?? '',
        telefone: point.telefone ?? '',
        materiaisAceitos: point.materiaisAceitos,
        usuarioId: service.currentUser?.uid,
      ),
    );

    if (!mounted) return;
    setState(() {
      _sent = true;
      _formVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugerir ponto de coleta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Informe um novo ponto de coleta. A sugestão ficará pendente até ser validada por um administrador ou empresa autorizada.',
                      style: TextStyle(
                        color: AppColors.onPrimaryContainer,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_sent) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Sugestão enviada para validação.',
                        style: TextStyle(
                          color: AppColors.onTertiaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  CollectionPointForm(
                    key: ValueKey(_formVersion),
                    submitLabel: 'Enviar sugestão',
                    onSubmit: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
