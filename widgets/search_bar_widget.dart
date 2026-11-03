import 'package:flutter/material.dart';

import '../app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final String filtroAtivo;
  final ValueChanged<String> onFilterSelected;
  final List<String> filtros;
  final bool carregando;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.filtroAtivo,
    required this.onFilterSelected,
    this.filtros = const ['Todos', 'Eletrônicos', 'Pilhas', 'Baterias', 'Óleo'],
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SearchInput(
          controller: controller,
          onSearch: onSearch,
          carregando: carregando,
        ),
        const SizedBox(height: 10),
        _FilterChips(
          filtros: filtros,
          filtroAtivo: filtroAtivo,
          onFilterSelected: onFilterSelected,
        ),
      ],
    );
  }
}

class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool carregando;

  const _SearchInput({
    required this.controller,
    required this.onSearch,
    required this.carregando,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search,
            color: AppColors.outline,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSearch(),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Buscar material ou local...',
                hintStyle: TextStyle(
                  color: AppColors.outline,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              if (controller.text.isEmpty) return const SizedBox.shrink();

              return IconButton(
                tooltip: 'Limpar',
                onPressed: () {
                  controller.clear();
                  onSearch();
                },
                icon: const Icon(Icons.close),
                color: AppColors.outline,
                iconSize: 20,
              );
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: carregando
                ? const Padding(
                    key: ValueKey('loading'),
                    padding: EdgeInsets.only(right: 14),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Padding(
                    key: const ValueKey('button'),
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      tooltip: 'Buscar',
                      onPressed: onSearch,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> filtros;
  final String filtroAtivo;
  final ValueChanged<String> onFilterSelected;

  const _FilterChips({
    required this.filtros,
    required this.filtroAtivo,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filtros.map((filtro) {
          final ativo = filtroAtivo.toLowerCase() == filtro.toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onFilterSelected(filtro),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: ativo
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: ativo
                        ? Colors.transparent
                        : AppColors.outlineVariant.withValues(alpha: 0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.045),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  filtro,
                  style: TextStyle(
                    color: ativo
                        ? AppColors.onPrimaryContainer
                        : AppColors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
