import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard_data.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../providers/farm_input_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/field_background.dart';
import '../login_screen.dart';
import 'dialogs/notifications_modal.dart';
import 'tabs/dss_tab.dart';
import 'tabs/farm_tab.dart';
import 'tabs/weather_tab.dart';
import 'tabs/prices_tab.dart';
import 'tabs/settings_tab.dart';

/// Shell: app bar + language toggle + bottom navigation + tab switching.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _dssIndex = 2;

  // Pagbukas ng app, DSS agad ang makikita.
  int _tab = _dssIndex;

  // (outlined icon, filled icon) - ang mga label ay galing sa ARB
  static const _icons = [
    (Icons.wb_sunny_outlined, Icons.wb_sunny_rounded),
    (Icons.landscape_outlined, Icons.landscape_rounded),
    (Icons.insights_outlined, Icons.insights_rounded),
    (Icons.sell_outlined, Icons.sell_rounded),
    (Icons.settings_outlined, Icons.settings_rounded),
  ];

  Widget _buildBody(DashboardProvider p, AppLocalizations t) {
    if (p.isLoading) return const LoadingView();
    if (p.hasError) return ErrorView(message: t.errorLoad, onRetry: p.load);

    final tabs = <Widget>[
      WeatherTab(p: p, onOpenDss: () => setState(() => _tab = 2)),
      FarmTab(p: p, onOpenDss: () => setState(() => _tab = 2)),
      const DssTab(),
      PricesTab(p: p),
      SettingsTab(p: p),
    ];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey('$_tab-${p.isTagalog}'),
        child: RefreshIndicator(
          color: AppColors.leaf,
          backgroundColor: Colors.white,
          onRefresh: p.load,
          child: tabs[_tab],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();
    if (!p.isLoggedIn) return LoginScreen(p: p);

    // Ipasa sa dashboard ang mga pananim na inilagay ng farmer sa DSS (presyo, hula).
    final farm = context.watch<FarmInputProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) p.syncPlantings(farm.plantings);
    });

    final t = AppLocalizations.of(context)!;
    final labels = [t.navWeather, t.navFarm, t.navDss, t.navPrices, t.navSettings];

    return Stack(children: [
      const Positioned.fill(child: FieldBackground()),
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _DashboardAppBar(p: p),
        body: Column(
          children: [
            if (p.weatherStale)
              Container(
                width: double.infinity,
                color: Colors.orange.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.offline_bolt_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Offline Mode - Viewing last cached update',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildBody(p, t)),
          ],
        ),
        bottomNavigationBar: _FloatingNav(
          selected: _tab,
          icons: _icons,
          labels: labels,
          onSelect: (i) => setState(() => _tab = i),
        ),
      ),
    ]);
  }
}

/// Lumulutang na "salamin" na navigation bar (bilugan, may blur).
/// Ang DSS (gitna) ay malaking berdeng bilog na bahagyang nakaangat - ang pangunahing button.
class _FloatingNav extends StatelessWidget {
  final int selected;
  final List<(IconData, IconData)> icons;
  final List<String> labels;
  final ValueChanged<int> onSelect;
  const _FloatingNav({required this.selected, required this.icons, required this.labels, required this.onSelect});

  static const double _barH = 68;
  static const double _lift = 26;
  static const double _circle = 62;

  @override
  Widget build(BuildContext context) {
    const r = BorderRadius.all(Radius.circular(30));
    const mid = _DashboardScreenState._dssIndex;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          height: _barH + _lift,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _barH,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: r,
                  boxShadow: [BoxShadow(color: Color(0x261B5E20), blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: ClipRRect(
                  borderRadius: r,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: r,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
                      ),
                      child: Row(children: [
                        for (var i = 0; i < icons.length; i++)
                          Expanded(
                            child: i == mid
                                ? _MainNavLabel(label: labels[i], selected: selected == i, onTap: () => onSelect(i))
                                : _NavItem(
                              icon: selected == i ? icons[i].$2 : icons[i].$1,
                              label: labels[i],
                              selected: selected == i,
                              onTap: () => onSelect(i),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Semantics(
                button: true,
                selected: selected == mid,
                label: labels[mid],
                child: GestureDetector(
                  onTap: () => onSelect(mid),
                  child: AnimatedScale(
                    scale: selected == mid ? 1.06 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: _circle,
                      height: _circle,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.fern, AppColors.leaf],
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.95), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.leaf.withValues(alpha: selected == mid ? 0.45 : 0.28),
                            blurRadius: selected == mid ? 22 : 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(icons[mid].$2, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Label ng DSS sa ilalim ng nakaangat na bilog (ang bilog mismo ay nasa itaas).
class _MainNavLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MainNavLabel({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Text(label,
              maxLines: 1,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: AppColors.leaf)),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.leaf : AppColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              color: selected ? AppColors.leaf.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 23, color: color),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1,
                  style: TextStyle(fontSize: 10.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: color)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DashboardProvider p;
  const _DashboardAppBar({required this.p});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(children: [
        const PagriLogo(height: 38),
        const SizedBox(width: 10),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('PAGRI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5)),
            Text(
              t.appSubtitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.leaf),
            ),
          ]),
        ),
      ]),
      actions: [
        _LanguageToggle(p: p),
        IconButton(
          tooltip: t.refresh,
          icon: const Icon(Icons.refresh_rounded),
          onPressed: p.isLoading ? null : () => p.load(),
        ),
        _NotificationBell(p: p),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final DashboardProvider p;
  const _NotificationBell({required this.p});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final unread = p.unreadNotificationCount;
    return Stack(alignment: Alignment.center, children: [
      IconButton(
        tooltip: t.notifications,
        icon: const Icon(Icons.notifications_rounded, color: AppColors.leaf),
        onPressed: () => showNotificationsModal(context, p),
      ),
      if (unread > 0)
        Positioned(
          top: 6,
          right: 6,
          child: IgnorePointer(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(unread),
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}

class _LanguageToggle extends StatelessWidget {
  final DashboardProvider p;
  const _LanguageToggle({required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _LangChip(label: 'Tagalog', selected: p.isTagalog, onTap: () => p.setLanguage(AppLanguage.tagalog)),
          _LangChip(label: 'English', selected: !p.isTagalog, onTap: () => p.setLanguage(AppLanguage.english)),
        ]),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentDark : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}