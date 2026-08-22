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
    this.adminSectionCount = 0,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  /// Shown at the right edge of the top bar (e.g. an account menu).
  final List<Widget>? actions;

  /// How many destinations, counted from the start of [destinations], form
  /// the "admin only" group — shown under its own heading, above a
  /// divider, before the rest ("General Features") on the extended
  /// sidebar (desktop always; tablet only while expanded — the compact
  /// rail and mobile's bottom nav have no room for section headings and
  /// always render as one plain list). 0 renders a single unlabeled list
  /// exactly as before, the case for every role except Super Admin, since
  /// only Super Admin ever sees a mix of both tiers at once.
  final int adminSectionCount;

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
    if (d.comingSoon) {
      return Badge(backgroundColor: AppColors.error, smallSize: 8, child: icon);
    }
    if (d.badgeCount > 0) {
      return Badge(
        label: Text('${d.badgeCount}'),
        backgroundColor: AppColors.error,
        child: icon,
      );
    }
    return icon;
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
            // NavigationRail doesn't scroll on its own, so on a short window
            // (or a role with many visible destinations) it would otherwise
            // overflow rather than clip — this lets it grow past the
            // viewport and scroll instead, while still filling the full
            // height on a normal-size window (the minHeight floor).
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height,
                ),
                child: IntrinsicHeight(
                  child: widget.adminSectionCount > 0
                      ? _GroupedNavRail(
                          key: const Key('groupedNavRail'),
                          destinations: widget.destinations,
                          railIcon: _railIcon,
                          adminSectionCount: widget.adminSectionCount,
                          selectedIndex: widget.selectedIndex,
                          onDestinationSelected: widget.onDestinationSelected,
                          leading: const ZeraLogo(height: 24),
                        )
                      : NavigationRail(
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
              ),
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
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height,
              ),
              child: IntrinsicHeight(
                child: _railExpanded && widget.adminSectionCount > 0
                    ? _GroupedNavRail(
                        key: const Key('groupedNavRail'),
                        destinations: widget.destinations,
                        railIcon: _railIcon,
                        adminSectionCount: widget.adminSectionCount,
                        selectedIndex: widget.selectedIndex,
                        onDestinationSelected: widget.onDestinationSelected,
                      )
                    : NavigationRail(
                        extended: _railExpanded,
                        labelType: _railExpanded
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        selectedIndex: widget.selectedIndex,
                        onDestinationSelected: widget.onDestinationSelected,
                        destinations: _railDestinations,
                      ),
              ),
            ),
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

/// Splits the extended sidebar into two labeled groups with a divider
/// between them, so a Super Admin can see at a glance which sidebar items
/// are Super-Admin-exclusive versus shared with other roles — see
/// [ResponsiveScaffold.adminSectionCount].
///
/// A hand-built list of rows rather than [NavigationRail] (even two
/// instances of it, one per group): stacking two [NavigationRail]s inside
/// a shared layout hits a genuine Flutter framework bug
/// (`_RenderObjectSemantics.debugCheckForParentData`'s
/// `!semantics.parentDataDirty` assertion firing on every frame) — likely
/// from two instances of a widget with as much internal animated/semantics
/// machinery as NavigationRail sharing one layout pass. Reusing the rail's
/// own theme tokens (`NavigationRailThemeData`) for indicator color/shape
/// and icon/label styling keeps this visually identical to the plain
/// single-rail case used everywhere else.
class _GroupedNavRail extends StatelessWidget {
  const _GroupedNavRail({
    super.key,
    required this.destinations,
    required this.railIcon,
    required this.adminSectionCount,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.leading,
  });

  final List<AppNavDestination> destinations;
  final Widget Function(AppNavDestination, {bool selected}) railIcon;
  final int adminSectionCount;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final railTheme = Theme.of(context).navigationRailTheme;

    return Container(
      width: railTheme.minExtendedWidth ?? 200,
      color: railTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Align(alignment: Alignment.centerLeft, child: leading),
            ),
          const _NavSectionLabel('Admin Only Features'),
          for (var i = 0; i < adminSectionCount; i++)
            _NavRow(
              destination: destinations[i],
              icon: railIcon,
              selected: i == selectedIndex,
              onTap: () => onDestinationSelected(i),
            ),
          const Divider(
            height: 24,
            indent: 16,
            endIndent: 16,
            color: AppColors.borderSubtle,
          ),
          const _NavSectionLabel('General Features'),
          for (var i = adminSectionCount; i < destinations.length; i++)
            _NavRow(
              destination: destinations[i],
              icon: railIcon,
              selected: i == selectedIndex,
              onTap: () => onDestinationSelected(i),
            ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.destination,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final AppNavDestination destination;
  final Widget Function(AppNavDestination, {bool selected}) icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final railTheme = Theme.of(context).navigationRailTheme;
    final labelStyle = selected
        ? railTheme.selectedLabelTextStyle
        : railTheme.unselectedLabelTextStyle;
    final iconTheme = selected
        ? railTheme.selectedIconTheme
        : railTheme.unselectedIconTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected
            ? (railTheme.indicatorColor ?? AppColors.primarySoft)
            : Colors.transparent,
        shape:
            railTheme.indicatorShape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          customBorder:
              railTheme.indicatorShape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconTheme(
                  data: iconTheme ?? const IconThemeData(),
                  child: icon(destination, selected: selected),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    destination.label,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSectionLabel extends StatelessWidget {
  const _NavSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
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
