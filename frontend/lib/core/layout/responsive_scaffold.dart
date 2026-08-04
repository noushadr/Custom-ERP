import 'package:flutter/material.dart';
import '../../shared/widgets/app_footer.dart';
import '../../shared/widgets/zera_logo.dart';
import 'app_nav_destination.dart';
import 'breakpoints.dart';

/// Adaptive app shell: permanent sidebar on desktop, collapsible sidebar on
/// tablet, bottom navigation on mobile.
class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.actions,
  });

  final String title;
  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Shown as AppBar actions on tablet/mobile, and below the rail on desktop.
  final List<Widget>? actions;

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  bool _railExpanded = false;

  List<NavigationRailDestination> get _railDestinations => [
    for (final d in widget.destinations)
      NavigationRailDestination(
        icon: Icon(d.icon),
        selectedIcon: Icon(d.selectedIcon),
        label: Text(d.label),
      ),
  ];

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
          NavigationRail(
            extended: true,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ZeraLogo(height: 28),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            trailing: widget.actions == null
                ? null
                : Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.actions!,
                        ),
                      ),
                    ),
                  ),
            destinations: _railDestinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _contentWithFooter(widget.body)),
        ],
      ),
    );
  }

  Widget _buildTablet() {
    return Scaffold(
      appBar: AppBar(
        title: _TitleWithLogo(title: widget.title),
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
          const VerticalDivider(width: 1),
          Expanded(child: _contentWithFooter(widget.body)),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    return Scaffold(
      appBar: AppBar(
        title: _TitleWithLogo(title: widget.title),
        actions: widget.actions,
      ),
      body: _contentWithFooter(widget.body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        destinations: [
          for (final d in widget.destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }

  Widget _contentWithFooter(Widget body) {
    return Column(
      children: [
        Expanded(child: body),
        const Divider(height: 1),
        const AppFooter(),
      ],
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
