import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app_colors.dart';
import '../models/place_model.dart';
import '../services/location_service.dart';

class CollectionPointForm extends StatefulWidget {
  final PlaceModel? initialValue;
  final String submitLabel;
  final Future<void> Function(PlaceModel point) onSubmit;

  const CollectionPointForm({
    super.key,
    this.initialValue,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<CollectionPointForm> createState() => _CollectionPointFormState();
}

class _CollectionPointFormState extends State<CollectionPointForm> {
  static const _tipos = [
    'Eletrônicos',
    'Pilhas',
    'Baterias',
    'Óleo de cozinha',
  ];

  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();

  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  late final TextEditingController _endereco;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _horario;
  late final TextEditingController _telefone;

  final Set<String> _materiais = {};
  bool _saving = false;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final point = widget.initialValue;
    _nome = TextEditingController(text: point?.nome ?? '');
    _descricao = TextEditingController(
      text: point?.descricao ?? point?.observacao ?? '',
    );
    _endereco = TextEditingController(text: point?.endereco ?? '');
    _latitude = TextEditingController(
      text: point == null ? '' : point.latitude.toString(),
    );
    _longitude = TextEditingController(
      text: point == null ? '' : point.longitude.toString(),
    );
    _horario = TextEditingController(text: point?.horarioFuncionamento ?? '');
    _telefone = TextEditingController(text: point?.telefone ?? '');
    _materiais.addAll(point?.materiaisAceitos ?? const []);
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _endereco.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _horario.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });

    final access = await _locationService.ensurePermission();
    if (!mounted) return;

    if (!access.granted) {
      setState(() {
        _locating = false;
        _error = access.message;
      });
      return;
    }

    try {
      final Position position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude.text = position.latitude.toStringAsFixed(6);
        _longitude.text = position.longitude.toStringAsFixed(6);
        _locating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _error = 'Não foi possível obter sua localização agora.';
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_materiais.isEmpty) {
      setState(() => _error = 'Selecione ao menos um tipo de resíduo aceito.');
      return;
    }

    final latitude = double.tryParse(_latitude.text.trim().replaceAll(',', '.'));
    final longitude = double.tryParse(_longitude.text.trim().replaceAll(',', '.'));

    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      setState(() => _error = 'Informe coordenadas geográficas válidas.');
      return;
    }

    final point = PlaceModel(
      id: widget.initialValue?.id,
      nome: _nome.text.trim(),
      descricao: _descricao.text.trim(),
      endereco: _endereco.text.trim(),
      latitude: latitude,
      longitude: longitude,
      horarioFuncionamento: _horario.text.trim(),
      telefone: _telefone.text.trim(),
      materiaisAceitos: _materiais.toList()..sort(),
      tipo: (_materiais.toList()..sort()).join(', '),
      status: widget.initialValue?.status ?? 'validado',
    );

    setState(() => _saving = true);

    try {
      await widget.onSubmit(point);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatório.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nome,
            validator: _required,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nome do ponto',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _endereco,
            validator: _required,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Endereço',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descricao,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _horario,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Horário de funcionamento (opcional)',
              helperText: 'Deixe em branco se não souber.',
              prefixIcon: Icon(Icons.schedule_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Contato (opcional)',
              helperText: 'Deixe em branco se não souber.',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tipos de resíduos aceitos',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tipos.map((tipo) {
              final selected = _materiais.contains(tipo);
              return FilterChip(
                label: Text(tipo),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _materiais.add(tipo);
                    } else {
                      _materiais.remove(tipo);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _latitude,
                  validator: _required,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _longitude,
                  validator: _required,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _locating ? 'Obtendo localização...' : 'Usar minha localização',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Salvando...' : widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
