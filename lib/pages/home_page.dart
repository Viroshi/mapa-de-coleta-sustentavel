import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'admin_page.dart';
import 'mapa_page.dart';
import 'suggest_point_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  int _mapRefreshToken = 0;

  void _selectPage(int index) {
    setState(() {
      _index = index;
      if (index == 0) {
        _mapRefreshToken++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      body: Column(
        children: [
          if (isDesktop)
            _TopNavBar(
              selectedIndex: _index,
              onSelected: _selectPage,
            ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                MapaPage(refreshToken: _mapRefreshToken),
                const SuggestPointPage(),
                const AdminPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _BottomNavBar(
              selectedIndex: _index,
              onSelected: _selectPage,
            ),
    );
  }
}

class _TopNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TopNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.recycling, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          const Text(
            'Mapa de Coleta Sustentável',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 19,
            ),
          ),
          const Spacer(),
          _DesktopNavButton(
            label: 'Mapa',
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          const SizedBox(width: 12),
          _DesktopNavButton(
            label: 'Sugerir ponto',
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          const SizedBox(width: 12),
          _DesktopNavButton(
            label: 'Administração',
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DesktopNavButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor:
            selected ? AppColors.primary : AppColors.onSurfaceVariant,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.96),
      elevation: 16,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _BottomNavItem(
                label: 'Mapa',
                icon: Icons.map_outlined,
                selectedIcon: Icons.map,
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              _BottomNavItem(
                label: 'Sugerir',
                icon: Icons.add_location_alt_outlined,
                selectedIcon: Icons.add_location_alt,
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
              _BottomNavItem(
                label: 'Admin',
                icon: Icons.admin_panel_settings_outlined,
                selectedIcon: Icons.admin_panel_settings,
                selected: selectedIndex == 2,
                onTap: () => onSelected(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
