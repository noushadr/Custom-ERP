import 'package:flutter/material.dart';
import '../../shared/widgets/app_footer.dart';
import '../../shared/widgets/zera_logo.dart';
import '../theme/app_colors.dart';
import 'app_nav_destination.dart';
import 'breakpoints.dart';

/// Adaptive app shell: permanent sidebar on desktop, collapsible sidebar on
/// tablet, bottom navigation on mobile. Every breakpoint gets a consistent
/// top bar showing the current section and account menu.
class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.actions,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Shown at the right edge of the top bar (e.g. an account menu).
  final List<Widget>? actions;

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  bool _railExpanded = false;

  String get _currentLabel => widget.destinations[widget.selectedIndex].label;

  List<NavigationRailDestination> get _railDestinations => [
    for (final d in widget.destinations)
      NavigationRailDestination(
        icon: _railIcon(d),
        selectedIcon: _railIcon(d, selected: true),
        label: Text(d.label),
      ),
  ];

  Widget _railIcon(AppNavDestination d, {bool selected = false}) {
    final icon = Icon(selected ? d.selectedIcon : d.icon);
    if (!d.comingSoon) return icon;
    return Badge(
      backgroundColor: AppColors.error,
      smallSize: 8,
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < Breakpoints.mobileMax) return _buildMobile();
    if (width < Breakpoints.tabletMax) return _buildTablet();
    return _buildDesktop();
  }

  Widget _buildDesktop() {
    return Scaffold(
      body: Row(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.borderSubtle),
              ),
            ),
            child: NavigationRail(
              extended: true,
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: const ZeraLogo(height: 24),
                ),
              ),
              destinations: _railDestinations,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: _currentLabel, actions: widget.actions),
                Expanded(child: _canvas(widget.body)),
                const AppFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablet() {
    return Scaffold(
      appBar: AppBar(
        title: _TitleWithLogo(title: _currentLabel),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: _railExpanded ? 'Collapse menu' : 'Expand menu',
          onPressed: () => setState(() => _railExpanded = !_railExpanded),
        ),
        actions: widget.actions,
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: _railExpanded,
            labelType: _railExpanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            destinations: _railDestinations,
          ),
          Expanded(child: _contentWithFooter(widget.body)),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    return Scaffold(
      appBar: AppBar(
        title: _TitleWithLogo(title: _currentLabel),
        actions: widget.actions,
      ),
      body: _contentWithFooter(widget.body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        destinations: [
          for (final d in widget.destinations)
            NavigationDestination(
              icon: _railIcon(d),
              selectedIcon: _railIcon(d, selected: true),
              label: d.label,
            ),
        ],
      ),
    );
  }

  Widget _contentWithFooter(Widget body) {
    return Column(
      children: [
        Expanded(child: _canvas(body)),
        const AppFooter(),
      ],
    );
  }

  Widget _canvas(Widget body) {
    return ColoredBox(color: AppColors.canvasBackground, child: body);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.navActive.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (actions != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
        ],
      ),
    );
  }
}

class _TitleWithLogo extends StatelessWidget {
  const _TitleWithLogo({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ZeraLogo(height: 24),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }
}
