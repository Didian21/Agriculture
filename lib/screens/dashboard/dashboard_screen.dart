import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../dashboard_data.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../providers/farm_input_provider.dart';
import '../../widgets/common_widgets.dart';
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
  int _tab = 0;

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
          backgroundColor: AppColors.surface,
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bg1, AppColors.bg0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _DashboardAppBar(p: p),
        body: _buildBody(p, t),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              for (var i = 0; i < _icons.length; i++)
                NavigationDestination(
                  icon: Icon(_icons[i].$1),
                  selectedIcon: Icon(_icons[i].$2),
                  label: labels[i],
                ),
            ],
          ),
        ),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
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