import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models/place_model.dart';
import '../models/suggestion_model.dart';
import '../services/firebase_service.dart';
import '../widgets/collection_point_form.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseService _service = FirebaseService.instance;
  bool _checking = true;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (!_service.isConfigured) {
      if (mounted) {
        setState(() {
          _checking = false;
          _authorized = false;
        });
      }
      return;
    }

    final authorized = await _service.usuarioAtualEhAdministrador();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _authorized = authorized;
    });
  }

  void _onLoggedIn() {
    setState(() => _authorized = true);
  }

  Future<void> _logout() async {
    await _service.sair();
    if (!mounted) return;
    setState(() => _authorized = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_service.isConfigured) {
      return const _FirebaseNotConfigured();
    }

    if (!_authorized) {
      return AdminLogin(onLoggedIn: _onLoggedIn);
    }

    return _AdminDashboard(onLogout: _logout);
  }
}

class _FirebaseNotConfigured extends StatelessWidget {
  const _FirebaseNotConfigured();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administração')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 34),
                  SizedBox(height: 12),
                  Text(
                    'Firebase ainda não configurado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'O painel administrativo e o envio de sugestões dependem do Firebase, conforme previsto no TCC. Configure o projeto Firebase antes de usar essas funções.',
                    style: TextStyle(height: 1.45),
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

class AdminLogin extends StatefulWidget {
  final VoidCallback onLoggedIn;

  const AdminLogin({super.key, required this.onLoggedIn});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await FirebaseService.instance.entrarComoAdministrador(
        email: _email.text,
        senha: _password.text,
      );

      if (!mounted) return;
      if (ok) {
        widget.onLoggedIn();
      } else {
        setState(() {
          _loading = false;
          _error = 'Usuário sem permissão de administrador ou empresa.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível entrar. Verifique e-mail, senha e conexão.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login administrativo')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 52,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Administrador / Empresa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acesso restrito a usuários autorizados para cadastrar, validar, editar e excluir pontos de coleta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o e-mail.'
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    onFieldSubmitted: (_) => _login(),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Informe a senha.'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _loading ? null : _login,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Entrar'),
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

class _AdminDashboard extends StatelessWidget {
  final Future<void> Function() onLogout;

  const _AdminDashboard({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel administrativo'),
          actions: [
            IconButton(
              tooltip: 'Sair',
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sugestões', icon: Icon(Icons.fact_check_outlined)),
              Tab(text: 'Pontos', icon: Icon(Icons.place_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SuggestionsTab(),
            _PointsTab(),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsTab extends StatelessWidget {
  const _SuggestionsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SuggestionModel>>(
      stream: FirebaseService.instance.observarSugestoesPendentes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _EmptyState(
            icon: Icons.error_outline,
            title: 'Não foi possível carregar as sugestões.',
          );
        }

        final suggestions = snapshot.data ?? const [];
        if (suggestions.isEmpty) {
          return const _EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nenhuma sugestão pendente.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.nome,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(suggestion.endereco),
                    const SizedBox(height: 5),
                    Text(
                      'Horário: ${suggestion.horarioFuncionamento.trim().isEmpty ? 'Não informado' : suggestion.horarioFuncionamento}',
                      style: const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      'Contato: ${suggestion.telefone.trim().isEmpty ? 'Não informado' : suggestion.telefone}',
                      style: const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      'Coordenadas: ${suggestion.latitude.toStringAsFixed(5)}, ${suggestion.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    if (suggestion.descricao.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(suggestion.descricao),
                    ],
                    if (suggestion.materiaisAceitos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: suggestion.materiaisAceitos
                            .map((item) => Chip(label: Text(item)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _validate(context, suggestion),
                          icon: const Icon(Icons.check),
                          label: const Text('Validar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _reject(context, suggestion),
                          icon: const Icon(Icons.close),
                          label: const Text('Rejeitar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _validate(BuildContext context, SuggestionModel suggestion) async {
    try {
      await FirebaseService.instance.validarSugestao(suggestion);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sugestão validada e ponto cadastrado.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível validar a sugestão.')),
      );
    }
  }

  Future<void> _reject(BuildContext context, SuggestionModel suggestion) async {
    final id = suggestion.id;
    if (id == null) return;

    try {
      await FirebaseService.instance.rejeitarSugestao(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sugestão rejeitada.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível rejeitar a sugestão.')),
      );
    }
  }
}

class _PointsTab extends StatelessWidget {
  const _PointsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<PlaceModel>>(
        stream: FirebaseService.instance.observarTodosOsPontos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const _EmptyState(
              icon: Icons.error_outline,
              title: 'Não foi possível carregar os pontos.',
            );
          }

          final points = snapshot.data ?? const [];
          if (points.isEmpty) {
            return const _EmptyState(
              icon: Icons.place_outlined,
              title: 'Nenhum ponto cadastrado no Firebase.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: points.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final point = points[index];
              return Card(
                child: ListTile(
                  title: Text(
                    point.nome,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    point.endereco?.isNotEmpty == true
                        ? point.endereco!
                        : point.materiaisAceitos.join(', '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openPointForm(context, point);
                      } else if (value == 'delete') {
                        _deletePoint(context, point);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPointForm(context, null),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Cadastrar ponto'),
      ),
    );
  }

  Future<void> _openPointForm(BuildContext context, PlaceModel? point) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(point == null ? 'Cadastrar ponto' : 'Editar ponto'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: CollectionPointForm(
                  initialValue: point,
                  submitLabel: point == null ? 'Cadastrar' : 'Salvar alterações',
                  onSubmit: (updated) async {
                    if (point == null) {
                      await FirebaseService.instance.cadastrarPonto(updated);
                    } else {
                      await FirebaseService.instance.atualizarPonto(updated);
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deletePoint(BuildContext context, PlaceModel point) async {
    final id = point.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir ponto?'),
        content: Text('O ponto "${point.nome}" será removido do sistema.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseService.instance.excluirPonto(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponto excluído.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o ponto.')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;

  const _EmptyState({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.outline),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
