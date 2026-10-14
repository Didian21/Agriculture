import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_config.dart';
import '../dashboard_data.dart';

// ==========================================
// SHELL: app bar + language selector + 4 tabs
// ==========================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DashboardProvider>();
    final isTagalog = p.isTagalog;

    if (!p.isLoggedIn) {
      return _LoginScreen(p: p);
    }

    Widget body;
    if (p.isLoading) {
      body = _LoadingView(isTagalog: isTagalog);
    } else if (p.error != null) {
      body = _ErrorView(message: p.error!, onRetry: p.load, isTagalog: isTagalog);
    } else {
      final tabs = <Widget>[
        HomeTab(p: p),
        FarmTab(p: p),
        PlantingTab(p: p),
        PricesTab(p: p),
        SettingsTab(p: p),
      ];
      body = AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey('$_tab-$isTagalog'), child: RefreshIndicator(onRefresh: p.load, child: tabs[_tab])),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          const PagriLogo(height: 38),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('PAGRI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.5)),
            Text(isTagalog ? 'Sektor ng Agrikultura ng Pagsanjan' : 'Pagsanjan Agriculture',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green[800])),
          ]),
        ]),
        actions: [
          // Notification Bell Button with Unread Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: isTagalog ? 'Mga Abiso' : 'Notifications',
                icon: const Icon(Icons.notifications_rounded, color: AppColors.leaf),
                onPressed: () => _showNotificationsModal(context, p),
              ),
              if (p.unreadNotificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${p.unreadNotificationCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Language choice toggle (Tagalog / English)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LangChip(
                    label: 'Tagalog',
                    selected: isTagalog,
                    onTap: () => p.setLanguage(AppLanguage.tagalog),
                  ),
                  _LangChip(
                    label: 'English',
                    selected: !isTagalog,
                    onTap: () => p.setLanguage(AppLanguage.english),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: isTagalog ? 'I-refresh' : 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: p.isLoading ? null : () => p.load(),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_sunny_outlined),
            selectedIcon: const Icon(Icons.wb_sunny_rounded),
            label: isTagalog ? 'Panahon' : 'Weather',
          ),
          NavigationDestination(
            icon: const Icon(Icons.landscape_outlined),
            selectedIcon: const Icon(Icons.landscape_rounded),
            label: isTagalog ? 'Aking Bukid' : 'My Farm',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: isTagalog ? 'Pagtatanim' : 'Planting',
          ),
          NavigationDestination(
            icon: const Icon(Icons.sell_outlined),
            selectedIcon: const Icon(Icons.sell_rounded),
            label: isTagalog ? 'Presyo' : 'Prices',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: isTagalog ? 'Mga Setting' : 'Settings',
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.leaf : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SMALL REUSABLE PIECES
// ==========================================

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? subtitle;
  const SectionTitle({super.key, required this.icon, required this.text, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(children: [
        Icon(icon, color: AppColors.leaf, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const _Pill(this.text, this.color, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final bool isTagalog;
  const _LoadingView({required this.isTagalog});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const PagriLogo(height: 90),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: AppColors.fern),
        const SizedBox(height: 16),
        Text(
          isTagalog ? 'Kina-karga ang panahon ng iyong bukid...' : 'Getting your farm weather...',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isTagalog;
  const _ErrorView({required this.message, required this.onRetry, required this.isTagalog});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.black38),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(isTagalog ? 'Subukang muli' : 'Try again'),
          ),
        ]),
      ),
    );
  }
}

class _Floating extends StatefulWidget {
  final Widget child;
  const _Floating({required this.child});

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(offset: Offset(0, math.sin(_c.value * 2 * math.pi) * 6), child: child),
      child: widget.child,
    );
  }
}

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_c),
      child: Container(width: 9, height: 9, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
    );
  }
}

// ==========================================
// TAB 1: WEATHER (front page)
// ==========================================

class HomeTab extends StatelessWidget {
  final DashboardProvider p;
  const HomeTab({super.key, required this.p});

  String _greeting(bool isTagalog) {
    final h = DateTime.now().hour;
    if (h < 12) return isTagalog ? 'Magandang umaga' : 'Good morning';
    if (h < 18) return isTagalog ? 'Magandang hapon' : 'Good afternoon';
    return isTagalog ? 'Magandang gabi' : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final w = p.weather!;
    final isTagalog = p.isTagalog;
    final firstName = p.profile!.name.split(' ').first;
    final month = DateTime.now().month;
    final plantNow = p.guides.where((g) => g.statusFor(month) == PlantStatus.best).toList();
    final monthNames = getMonthNames(isTagalog);

    final items = <Widget>[
      Text('${_greeting(isTagalog)}, $firstName!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      Text(DateFormat('EEEE, MMMM d, y').format(DateTime.now()), style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 14),
      _WeatherHero(w: w, updated: p.lastUpdated, stale: p.weatherStale, place: p.profile!.barangay, isTagalog: isTagalog),
      const SizedBox(height: 18),
      SectionTitle(
        icon: Icons.access_time_rounded,
        text: isTagalog ? 'Susunod na 12 oras' : 'Next 12 hours',
      ),
      _HourlyStrip(hours: w.hourly, isTagalog: isTagalog),
      const SizedBox(height: 18),
      SectionTitle(
        icon: Icons.tips_and_updates_rounded,
        text: isTagalog ? 'Payo sa pagsasaka ngayong araw' : "Today's farm advice",
        subtitle: isTagalog ? 'Batay sa kasalukuyang panahon' : 'Based on the live weather',
      ),
      ...p.advice.map((a) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _AdviceCard(a: a, isTagalog: isTagalog))),
      const SizedBox(height: 8),
      SectionTitle(
        icon: Icons.date_range_rounded,
        text: isTagalog ? 'Pagtaya sa 7 araw' : '7-day forecast',
      ),
      _DailyList(days: w.daily, isTagalog: isTagalog),
      const SizedBox(height: 18),
      SectionTitle(
        icon: Icons.eco_rounded,
        text: isTagalog ? 'Magandang itanim ngayong ${monthNames[month - 1]}' : 'Good to plant in ${monthNames[month - 1]}',
      ),
      _PlantNowCard(guides: plantNow, isTagalog: isTagalog),
      const SizedBox(height: 18),
      if (p.notifications.isNotEmpty) ...[
        SectionTitle(
          icon: Icons.notifications_active_rounded,
          text: isTagalog ? 'Mga Abiso sa Sistema' : 'System Notifications',
          subtitle: isTagalog ? 'Pinakabagong balita at paalala para sa magsasaka' : 'Latest alerts and reminders for farmers',
        ),
        ...p.notifications.take(2).map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: n.isRead ? AppColors.mint : AppColors.leaf.withValues(alpha: 0.2),
                child: Icon(n.icon, color: AppColors.leaf, size: 20),
              ),
              title: Text(n.title(isTagalog), style: TextStyle(fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w900)),
              subtitle: Text(n.message(isTagalog), maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showNotificationsModal(context, p),
            ),
          ),
        )),
      ],
      const SizedBox(height: 24),
    ];

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => FadeSlideIn(index: math.min(i, 6), child: items[i]),
    );
  }
}

class _WeatherHero extends StatelessWidget {
  final WeatherBundle w;
  final DateTime? updated;
  final bool stale;
  final String place;
  final bool isTagalog;

  const _WeatherHero({
    required this.w,
    required this.updated,
    required this.stale,
    required this.place,
    required this.isTagalog,
  });

  @override
  Widget build(BuildContext context) {
    final c = w.current;
    final info = c.info;
    final today = w.daily.first;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: info.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: info.gradient.last.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Expanded(child: Text('$place, Pagsanjan', style: const TextStyle(fontWeight: FontWeight.w700))),
            _LiveDot(color: stale ? Colors.orangeAccent : Colors.lightGreenAccent),
            const SizedBox(width: 6),
            Text(
              stale
                  ? (isTagalog ? 'WALANG INTERNET' : 'OFFLINE')
                  : (isTagalog ? 'KASALUKUYAN' : 'LIVE'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: c.temp),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text('${v.round()}°',
                      style: const TextStyle(fontSize: 76, fontWeight: FontWeight.w900, height: 1.0)),
                ),
                const SizedBox(height: 4),
                Text(info.label(isTagalog), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                if (!isTagalog) Text(info.labelTl, style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ]),
            ),
            _Floating(child: Icon(info.icon, size: 96, color: c.code <= 1 && c.isDay ? const Color(0xFFFFE082) : Colors.white)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _HeroStat(Icons.thermostat_rounded, isTagalog ? 'Nararamdaman' : 'Feels like', '${c.feelsLike.round()}°'),
            _HeroStat(Icons.water_drop_rounded, isTagalog ? 'Halumigmig' : 'Humidity', '${c.humidity}%'),
            _HeroStat(Icons.air_rounded, isTagalog ? 'Hangin' : 'Wind', '${c.windKmh.round()} km/h'),
            _HeroStat(Icons.umbrella_rounded, isTagalog ? 'Tsansa ng ulan' : 'Rain chance', '${today.rainChance}%'),
          ]),
          const SizedBox(height: 12),
          Text(
            isTagalog
                ? 'Ngayong araw: ${today.tempMin.round()}° - ${today.tempMax.round()}°   •   Ulan ${today.rainMm.toStringAsFixed(1)} mm'
                  '${updated != null ? '\nNa-update ${DateFormat('h:mm a').format(updated!)}  (awtomatikong nagre-refresh kada 10 min)' : ''}'
                : 'Today: ${today.tempMin.round()}° - ${today.tempMax.round()}°   •   Rain ${today.rainMm.toStringAsFixed(1)} mm'
                  '${updated != null ? '\nUpdated ${DateFormat('h:mm a').format(updated!)}  (auto-refresh every 10 min)' : ''}',
            style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
          ),
        ]),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HeroStat(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _HourlyStrip extends StatelessWidget {
  final List<HourlyWeather> hours;
  final bool isTagalog;
  const _HourlyStrip({required this.hours, required this.isTagalog});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hours.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final h = hours[i];
          final info = describeWeather(h.code, isDay: h.isDay);
          return Container(
            width: 68,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: i == 0 ? AppColors.leaf : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD7E8D4)),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: i == 0 ? Colors.white : AppColors.ink),
              child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  i == 0
                      ? (isTagalog ? 'Ngayon' : 'Now')
                      : DateFormat('h a').format(h.time),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                Icon(info.icon, color: i == 0 ? Colors.white : info.gradient.last, size: 26),
                Text('${h.temp.round()}°', style: const TextStyle(fontWeight: FontWeight.w900)),
                Text('${h.rainChance}%', style: const TextStyle(fontSize: 10)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final FarmAdvice a;
  final bool isTagalog;
  const _AdviceCard({required this.a, required this.isTagalog});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: a.color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(a.icon, color: a.color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title(isTagalog), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 2),
              Text(a.message(isTagalog), style: const TextStyle(height: 1.35)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _DailyList extends StatelessWidget {
  final List<WeatherDay> days;
  final bool isTagalog;
  const _DailyList({required this.days, required this.isTagalog});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        child: Column(
          children: [
            for (var i = 0; i < days.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      i == 0
                          ? (isTagalog ? 'Ngayon' : 'Today')
                          : DateFormat('EEE d').format(days[i].date),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(describeWeather(days[i].code).icon, color: describeWeather(days[i].code).gradient.last, size: 24),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Row(children: [
                      const Icon(Icons.water_drop, size: 13, color: AppColors.rain),
                      const SizedBox(width: 2),
                      Text('${days[i].rainChance}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  Expanded(
                    child: Text('${days[i].rainMm.toStringAsFixed(1)} mm',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ),
                  Text('${days[i].tempMin.round()}° / ${days[i].tempMax.round()}°',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlantNowCard extends StatelessWidget {
  final List<PlantingGuide> guides;
  final bool isTagalog;
  const _PlantNowCard({required this.guides, required this.isTagalog});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.mint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: guides.isEmpty
            ? Text(isTagalog
                ? 'Walang pananim na nasa pinakamagandang panahon ng pagtatanim ngayong buwan.'
                : 'No crop is at its best planting time this month. See the Planting tab for the calendar.')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: guides
                    .map((g) => Chip(
                          avatar: Icon(g.icon, size: 18, color: AppColors.forCrop(g.cropEn)),
                          label: Text(g.crop(isTagalog), style: const TextStyle(fontWeight: FontWeight.w800)),
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
      ),
    );
  }
}

// ==========================================
// TAB 2: MY FARM
// ==========================================

class FarmTab extends StatelessWidget {
  final DashboardProvider p;
  const FarmTab({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final isTagalog = p.isTagalog;

    final items = <Widget>[
      ProfileCard(profile: p.profile!, isTagalog: isTagalog),
      const SizedBox(height: 16),
      LandCard(profile: p.profile!, plots: p.plots, isTagalog: isTagalog),
      const SizedBox(height: 16),
      SectionTitle(
        icon: Icons.grass_rounded,
        text: isTagalog ? 'Ano ang nakatanim at saan' : 'What is planted where',
      ),
      ...p.plots.map((pl) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlotTile(plot: pl, total: p.profile!.landSizeHectares, isTagalog: isTagalog),
          )),
      const SizedBox(height: 8),
      CropHistoryList(records: p.history, isTagalog: isTagalog),
      const SizedBox(height: 24),
    ];
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => FadeSlideIn(index: math.min(i, 6), child: items[i]),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final FarmerProfile profile;
  final bool isTagalog;
  const ProfileCard({super.key, required this.profile, required this.isTagalog});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.leaf,
                child: Icon(Icons.agriculture, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(profile.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: AppColors.soil),
                    const SizedBox(width: 3),
                    Flexible(child: Text('${profile.barangay}, Pagsanjan, Laguna')),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: profile.cropTypes
                  .map((c) => Chip(
                        avatar: Icon(Icons.eco, size: 16, color: AppColors.forCrop(c)),
                        label: Text(translateCrop(c, isTagalog), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        backgroundColor: AppColors.mint,
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class LandCard extends StatelessWidget {
  final FarmerProfile profile;
  final List<FarmPlot> plots;
  final bool isTagalog;

  const LandCard({
    super.key,
    required this.profile,
    required this.plots,
    required this.isTagalog,
  });

  @override
  Widget build(BuildContext context) {
    final total = profile.landSizeHectares;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isTagalog ? 'Kabuuan ng sukat ng lupa' : 'Total land size',
            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => Text(v.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.leaf, height: 1.1)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Text(isTagalog ? 'hektarya' : 'hectares', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _Pill('${(total * 10000).toStringAsFixed(0)} mkv', AppColors.soil, icon: Icons.square_foot_rounded),
            ),
          ]),
          const SizedBox(height: 14),
          Container(
            height: 18,
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(9)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (_, v, child) => Align(alignment: Alignment.centerLeft, widthFactor: v, child: child),
                child: Row(children: [
                  for (final pl in plots)
                    Expanded(flex: (pl.hectares * 100).round(), child: Container(color: AppColors.forCrop(pl.crop))),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 14, runSpacing: 6, children: [
            for (final pl in plots)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: AppColors.forCrop(pl.crop), shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('${pl.cropName(isTagalog)} ${(pl.hectares / total * 100).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
          ]),
        ]),
      ),
    );
  }
}

class _PlotTile extends StatelessWidget {
  final FarmPlot plot;
  final double total;
  final bool isTagalog;

  const _PlotTile({
    required this.plot,
    required this.total,
    required this.isTagalog,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forCrop(plot.crop);
    final growing = plot.statusEn == 'Growing';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(growing ? Icons.grass_rounded : Icons.check_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plot.cropName(isTagalog), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text('${plot.hectares} ${isTagalog ? 'hektarya' : 'hectares'}', style: const TextStyle(color: Colors.black54)),
            ]),
          ),
          _Pill(
            plot.status(isTagalog),
            growing ? AppColors.fern : AppColors.soil,
            icon: growing ? Icons.spa_rounded : Icons.inventory_2_rounded,
          ),
        ]),
      ),
    );
  }
}

class CropHistoryList extends StatelessWidget {
  final List<CropRecord> records;
  final bool isTagalog;

  const CropHistoryList({super.key, required this.records, required this.isTagalog});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(
            icon: Icons.history_rounded,
            text: isTagalog ? 'Kasaysayan ng pananim' : 'Crop record history',
          ),
          ...records.map((r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  r.isHarvested ? Icons.check_circle : Icons.grass,
                  color: r.isHarvested ? AppColors.leaf : AppColors.soil,
                  size: 28,
                ),
                title: Text(r.cropName(isTagalog), style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  isTagalog
                      ? 'Itinanim noong ${fmt.format(r.datePlanted)}'
                        '${r.isHarvested ? '\nNaani noong ${fmt.format(r.dateHarvested!)}' : '\nLumalaki pa'}'
                      : 'Planted ${fmt.format(r.datePlanted)}'
                        '${r.isHarvested ? '\nHarvested ${fmt.format(r.dateHarvested!)}' : '\nStill growing'}',
                ),
                isThreeLine: true,
                trailing: Text(
                  r.isHarvested ? '${NumberFormat('#,###').format(r.yieldKg)} kg' : '-',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              )),
        ]),
      ),
    );
  }
}

// ==========================================
// TAB 3: PLANTING CALENDAR
// ==========================================

class PlantingTab extends StatefulWidget {
  final DashboardProvider p;
  const PlantingTab({super.key, required this.p});

  @override
  State<PlantingTab> createState() => _PlantingTabState();
}

class _PlantingTabState extends State<PlantingTab> {
  int _month = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final guides = widget.p.guides;
    final mine = widget.p.profile!.cropTypes;
    final isTagalog = widget.p.isTagalog;
    final nowMonth = DateTime.now().month;
    final monthNames = getMonthNames(isTagalog);

    final items = <Widget>[
      Text(
        isTagalog ? 'Kailan magandang magtanim?' : 'When should I plant?',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      Text(
        isTagalog ? 'Pindutin ang buwan upang makita ang magandang itanim.' : 'Tap a month to see which crops are best to plant.',
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 12,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final m = i + 1;
            final sel = m == _month;
            return GestureDetector(
              onTap: () => setState(() => _month = m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppColors.leaf : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: sel ? AppColors.leaf : const Color(0xFFD7E8D4)),
                ),
                child: Text(
                  monthNames[i].substring(0, 3) + (m == nowMonth ? ' •' : ''),
                  style: TextStyle(fontWeight: FontWeight.w800, color: sel ? Colors.white : AppColors.ink),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      Row(children: [
        _LegendDot(AppColors.leaf, isTagalog ? 'Pinakamaganda' : 'Best'),
        const SizedBox(width: 14),
        _LegendDot(const Color(0xFFA5D6A7), isTagalog ? 'Maaari' : 'Possible'),
        const SizedBox(width: 14),
        _LegendDot(const Color(0xFFE0E0E0), isTagalog ? 'Hindi inirerekomenda' : 'Not advised'),
      ]),
      const SizedBox(height: 12),
      ...guides.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GuideCard(guide: g, month: _month, isMine: mine.contains(g.cropEn), isTagalog: isTagalog),
          )),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          isTagalog
              ? 'Ito ay pangkalahatang gabay para sa Laguna. Ang panahon ay maaaring magbago - mangyaring sumangguni rin sa Municipal Agriculture Office.'
              : 'This is a general guide for Laguna. Weather can change from year to year - please confirm with your Municipal Agriculture Office.',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ),
      const SizedBox(height: 16),
    ];

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => FadeSlideIn(index: math.min(i, 6), child: items[i]),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendDot(this.color, this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ]);
}

class _GuideCard extends StatelessWidget {
  final PlantingGuide guide;
  final int month;
  final bool isMine;
  final bool isTagalog;

  const _GuideCard({
    required this.guide,
    required this.month,
    required this.isMine,
    required this.isTagalog,
  });

  @override
  Widget build(BuildContext context) {
    final status = guide.statusFor(month);
    final Color sc;
    final String label;
    final IconData si;
    switch (status) {
      case PlantStatus.best:
        sc = AppColors.leaf;
        label = isTagalog ? 'Pinakamagandang magtanim' : 'Best time to plant';
        si = Icons.thumb_up_rounded;
        break;
      case PlantStatus.possible:
        sc = const Color(0xFFEF8F00);
        label = isTagalog ? 'Maaaring magtanim' : 'Can plant, some risk';
        si = Icons.help_outline_rounded;
        break;
      case PlantStatus.avoid:
        sc = Colors.black45;
        label = isTagalog ? 'Hindi inirerekomenda ngayon' : 'Not advised now';
        si = Icons.block_rounded;
        break;
    }
    const letters = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: AppColors.forCrop(guide.cropEn).withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(guide.icon, color: AppColors.forCrop(guide.cropEn)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(guide.crop(isTagalog), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
            if (isMine) _Pill(isTagalog ? 'Aking tanim' : 'My crop', AppColors.soil, icon: Icons.star_rounded),
          ]),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Row(key: ValueKey('$status-$isTagalog'), children: [
              _Pill(label, sc, icon: si),
              if (status == PlantStatus.avoid) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isTagalog
                        ? 'Pinakamaganda: ${guide.nextBestMonthName(month, true)}'
                        : 'Best: ${guide.nextBestMonthName(month, false)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            for (var m = 1; m <= 12; m++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: guide.bestMonths.contains(m)
                        ? AppColors.leaf
                        : guide.possibleMonths.contains(m)
                            ? const Color(0xFFA5D6A7)
                            : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(8),
                    border: m == month ? Border.all(color: AppColors.ink, width: 2) : null,
                  ),
                  child: Text(letters[m - 1],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: guide.bestMonths.contains(m) ? Colors.white : Colors.black54,
                      )),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 16, color: AppColors.soil),
            const SizedBox(width: 5),
            Text(
              isTagalog
                  ? 'Maaani pagkaraan ng ${guide.harvestTime(true)}'
                  : 'Ready to harvest in ${guide.harvestTime(false)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ]),
          const SizedBox(height: 6),
          Text(guide.tip(isTagalog), style: const TextStyle(height: 1.35, color: Colors.black87)),
        ]),
      ),
    );
  }
}

// ==========================================
// TAB 4: PRICES
// ==========================================

class PricesTab extends StatelessWidget {
  final DashboardProvider p;
  const PricesTab({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final isTagalog = p.isTagalog;

    final items = <Widget>[
      Text(
        isTagalog ? 'Presyo ng mga pananim' : 'Crop prices',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      Text(
        isTagalog
            ? 'Inaasahang presyo batay sa darating na panahon. Sa PHP bawat kg.'
            : 'Expected price based on the coming weather. In PHP per kg.',
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 14),
      if (p.predictions.isEmpty)
        Text(isTagalog ? 'Wala pang datos ng presyo para sa iyong mga tanim.' : 'No price data for your crops yet.'),
      ...p.predictions.map((pr) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PriceCard(pr: pr, isTagalog: isTagalog),
          )),
      const SizedBox(height: 16),
    ];
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => FadeSlideIn(index: math.min(i, 6), child: items[i]),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final PricePrediction pr;
  final bool isTagalog;

  const _PriceCard({required this.pr, required this.isTagalog});

  @override
  Widget build(BuildContext context) {
    final up = pr.changePercent >= 0;
    final color = up ? Colors.green[800]! : Colors.red[700]!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(pr.cropName(isTagalog), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
            _Pill('${up ? '+' : ''}${pr.changePercent.toStringAsFixed(1)}%', color,
                icon: up ? Icons.trending_up_rounded : Icons.trending_down_rounded),
          ]),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isTagalog ? 'Ngayon' : 'Now', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text('₱${pr.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Icon(Icons.arrow_forward_rounded, color: Colors.black38)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isTagalog ? 'Inaasahan' : 'Expected', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: pr.currentPrice, end: pr.predictedPrice),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text('₱${v.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
              ),
            ]),
          ]),
          const SizedBox(height: 10),
          Text(pr.reason(isTagalog), style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.lightbulb_rounded, color: AppColors.sun, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(pr.sellTip(isTagalog), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ==========================================
// DASHBOARD NOTIFICATIONS MODAL
// ==========================================

void _showNotificationsModal(BuildContext context, DashboardProvider p) {
  final isTagalog = p.isTagalog;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.leaf, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isTagalog ? 'Mga Abiso sa Dashboard' : 'Dashboard Notifications',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                  if (p.unreadNotificationCount > 0)
                    TextButton(
                      onPressed: () {
                        p.markAllNotificationsRead();
                        setModalState(() {});
                      },
                      child: Text(
                        isTagalog ? 'Basahin lahat' : 'Mark all read',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const Divider(height: 20),
              if (p.notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      isTagalog ? 'Walang bagong abiso sa kasalukuyan.' : 'No new notifications right now.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: p.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final n = p.notifications[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: n.isRead ? AppColors.mint : AppColors.leaf.withValues(alpha: 0.2),
                          child: Icon(n.icon, color: AppColors.leaf, size: 22),
                        ),
                        title: Text(
                          n.title(isTagalog),
                          style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(n.message(isTagalog), style: const TextStyle(fontSize: 13, height: 1.3)),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d • h:mm a').format(n.time),
                              style: const TextStyle(fontSize: 11, color: Colors.black45),
                            ),
                          ],
                        ),
                        trailing: !n.isRead
                            ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.leaf, shape: BoxShape.circle))
                            : null,
                        onTap: () {
                          p.markNotificationRead(n.id);
                          setModalState(() {});
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

// ==========================================
// TAB 5: SETTINGS
// ==========================================

class SettingsTab extends StatelessWidget {
  final DashboardProvider p;
  const SettingsTab({super.key, required this.p});

  void _showEditProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _EditProfileDialog(p: p),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _PrivacyPolicyDialog(p: p),
    );
  }

  void _confirmLogout(BuildContext context) {
    final isTagalog = p.isTagalog;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.logout_rounded, color: Colors.redAccent),
          const SizedBox(width: 8),
          Text(isTagalog ? 'Mag-log out' : 'Log Out'),
        ]),
        content: Text(
          isTagalog
              ? 'Sigurado ka bang gusto mong mag-log out sa iyong PAGRI portal?'
              : 'Are you sure you want to log out of your PAGRI portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isTagalog ? 'Kanselahin' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.pop(ctx);
              p.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            child: Text(isTagalog ? 'I-log out' : 'Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTagalog = p.isTagalog;
    final profile = p.profile;

    final items = <Widget>[
      Text(
        isTagalog ? 'Mga Setting ng App' : 'App Settings',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      Text(
        isTagalog
            ? 'Pamahalaan ang iyong account, mga abiso, at seguridad.'
            : 'Manage your profile, notification alerts, and privacy.',
        style: const TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 16),

      // Profile Header Card
      if (profile != null)
        Card(
          color: AppColors.mint,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.leaf,
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text('${profile.barangay}, Pagsanjan', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${profile.landSizeHectares} ${isTagalog ? 'hektarya' : 'hectares'}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.leaf),
                  ),
                  onPressed: () => _showEditProfile(context),
                  icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.leaf),
                  label: Text(
                    isTagalog ? 'Baguhin' : 'Edit',
                    style: const TextStyle(color: AppColors.leaf, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),

      const SizedBox(height: 18),

      // ACCOUNT SECTION
      SectionTitle(
        icon: Icons.manage_accounts_rounded,
        text: isTagalog ? 'Kwentong Account' : 'Account Details',
      ),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android_rounded, color: AppColors.leaf),
              title: Text(isTagalog ? 'Numero ng Telepono' : 'Phone Number', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(p.phoneNumber),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.square_foot_rounded, color: AppColors.leaf),
              title: Text(isTagalog ? 'Sukat ng Lupa' : 'Land Size', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${profile?.landSizeHectares ?? 0} ${isTagalog ? 'hektarya' : 'hectares'}'),
            ),
          ],
        ),
      ),

      const SizedBox(height: 18),

      // NOTIFICATIONS SECTION
      SectionTitle(
        icon: Icons.notifications_active_rounded,
        text: isTagalog ? 'Mga Abiso' : 'Notification Settings',
        subtitle: isTagalog ? 'Tukuyin kung aling babala ang gustong matanggap' : 'Choose what alerts you want to receive',
      ),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.thunderstorm_rounded, color: AppColors.rain),
              activeThumbColor: AppColors.leaf,
              title: Text(isTagalog ? 'Babala sa Panahon at Bagyo' : 'Weather & Typhoon Alerts', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(isTagalog ? 'Tumanggap ng abiso kapag may lalapit na ulan o bagyo' : 'Get alerts when storm or heavy rain is approaching'),
              value: p.notifyWeatherAlerts,
              onChanged: (v) => p.setNotifyWeather(v),
            ),
            const Divider(height: 1, indent: 56),
            SwitchListTile(
              secondary: const Icon(Icons.trending_up_rounded, color: AppColors.sun),
              activeThumbColor: AppColors.leaf,
              title: Text(isTagalog ? 'Pagbabago sa Presyo ng Pananim' : 'Crop Price Alerts', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(isTagalog ? 'Sabihan kapag tumaas o bumaba ang presyo ng pananim' : 'Get notified on sudden market price changes'),
              value: p.notifyPriceAlerts,
              onChanged: (v) => p.setNotifyPrice(v),
            ),
            const Divider(height: 1, indent: 56),
            SwitchListTile(
              secondary: const Icon(Icons.calendar_month_rounded, color: AppColors.fern),
              activeThumbColor: AppColors.leaf,
              title: Text(isTagalog ? 'Paalala sa Pagtatanim at Pag-aani' : 'Planting & Harvest Reminders', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(isTagalog ? 'Paalala sa takdang panahon ng pagpapatubig at pag-aani' : 'Reminders for scheduled farming and harvesting tasks'),
              value: p.notifyPlantingReminders,
              onChanged: (v) => p.setNotifyPlanting(v),
            ),
            const Divider(height: 1, indent: 56),
            SwitchListTile(
              secondary: const Icon(Icons.mark_as_unread_rounded, color: AppColors.leaf),
              activeThumbColor: AppColors.leaf,
              title: Text(isTagalog ? 'Pangaraw-araw na Payo sa Pagsasaka' : 'Daily Farming Advisory', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(isTagalog ? 'Tumanggap ng payo sa pagsasaka tuwing umaga' : 'Receive daily morning agricultural recommendations'),
              value: p.notifyDailyAdvisory,
              onChanged: (v) => p.setNotifyDailyAdvisory(v),
            ),
          ],
        ),
      ),

      const SizedBox(height: 18),

      // PRIVACY POLICY SECTION
      SectionTitle(
        icon: Icons.privacy_tip_rounded,
        text: isTagalog ? 'Patakaran sa Pagkapribado' : 'Privacy Policy',
      ),
      Card(
        color: AppColors.mint.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppColors.leaf),
                  const SizedBox(width: 8),
                  Text(
                    isTagalog ? 'Sistema ng Agrikultura ng Pagsanjan' : 'Pagsanjan Agriculture System',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isTagalog
                    ? 'Ang PAGRI (Pagsanjan Agricultural Decision Support System) ay nangangalaga sa datos ng bawat rehistradong magsasaka. Ang mga impormasyon tulad ng barangay, sukat ng lupa, at mga pananim ay ginagamit lamang sa pagbibigay ng tumpak na taya ng panahon, presyo sa pamilihan, at tulong mula sa Municipal Agriculture Office.'
                    : 'PAGRI (Pagsanjan Agricultural Decision Support System) protects the data of every registered farmer. Information such as barangay, land size, and crops are used solely for weather forecasting, market pricing, and support from the Municipal Agriculture Office.',
                style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.leaf),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () => _showPrivacyPolicy(context),
                  icon: const Icon(Icons.description_rounded, color: AppColors.leaf, size: 18),
                  label: Text(
                    isTagalog ? 'Basahin ang Buong Patakaran sa Pagkapribado' : 'Read Full Privacy Policy',
                    style: const TextStyle(color: AppColors.leaf, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 18),

      // LOG OUT SECTION (AT THE VERY BOTTOM)
      Card(
        color: Colors.red[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                isTagalog ? 'Mag-log out' : 'Log Out',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ),
      ),

      const SizedBox(height: 24),
    ];

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => FadeSlideIn(index: math.min(i, 6), child: items[i]),
    );
  }
}

// ==========================================
// EDIT PROFILE DIALOG
// ==========================================

class _EditProfileDialog extends StatefulWidget {
  final DashboardProvider p;
  const _EditProfileDialog({required this.p});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameCtrl = TextEditingController(text: widget.p.profile?.name);
  late final TextEditingController _barangayCtrl = TextEditingController(text: widget.p.profile?.barangay);
  late final TextEditingController _landCtrl = TextEditingController(text: widget.p.profile?.landSizeHectares.toString());

  @override
  void dispose() {
    _nameCtrl.dispose();
    _barangayCtrl.dispose();
    _landCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final isTagalog = widget.p.isTagalog;
    final name = _nameCtrl.text.trim();
    final barangay = _barangayCtrl.text.trim();
    final land = double.tryParse(_landCtrl.text.trim());

    if (name.isEmpty || barangay.isEmpty || land == null || land <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isTagalog ? 'Mangyaring punan ang tamang datos.' : 'Please enter valid information.')),
      );
      return;
    }

    widget.p.updateAccount(name: name, barangay: barangay, landSize: land);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.leaf,
        content: Text(isTagalog ? 'Na-update nang matagumpay ang iyong profile!' : 'Profile updated successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTagalog = widget.p.isTagalog;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        const Icon(Icons.edit_note_rounded, color: AppColors.leaf, size: 28),
        const SizedBox(width: 8),
        Text(isTagalog ? 'I-edit ang Profile' : 'Edit Profile'),
      ]),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isTagalog ? 'Pangalan ng Magsasaka' : 'Farmer Name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _barangayCtrl,
              decoration: InputDecoration(
                labelText: isTagalog ? 'Barangay' : 'Barangay',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _landCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isTagalog ? 'Sukat ng Lupa (hektarya)' : 'Land Size (hectares)',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isTagalog ? 'Kanselahin' : 'Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
          onPressed: _save,
          child: Text(isTagalog ? 'I-save' : 'Save'),
        ),
      ],
    );
  }
}

// ==========================================
// PRIVACY POLICY DIALOG
// ==========================================

class _PrivacyPolicyDialog extends StatelessWidget {
  final DashboardProvider p;
  const _PrivacyPolicyDialog({required this.p});

  @override
  Widget build(BuildContext context) {
    final isTagalog = p.isTagalog;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.privacy_tip_rounded, color: AppColors.leaf, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isTagalog ? 'Patakaran sa Pagkapribado' : 'Privacy Policy',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTagalog
                    ? 'Sistema ng Suporta sa Pagdedesisyon sa Agrikultura (PAGRI - Pagsanjan, Laguna)'
                    : 'Agricultural Decision Support System (PAGRI - Pagsanjan, Laguna)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.leaf),
              ),
              const SizedBox(height: 12),

              _PolicySection(
                title: isTagalog ? '1. Pangongolekta ng Datos' : '1. Information We Collect',
                body: isTagalog
                    ? 'Kinokolekta lamang ng PAGRI ang kinakailangang impormasyon ng magsasaka tulad ng pangalan, barangay, sukat ng lupa, at uri ng mga pananim upang magbigay ng tumpak na pagtaya sa panahon at presyo.'
                    : 'PAGRI collects basic farmer information including name, barangay, land size, and crop types to generate localized weather advisories and price forecasts.',
              ),
              const SizedBox(height: 10),

              _PolicySection(
                title: isTagalog ? '2. Paggamit ng Impormasyon' : '2. How Information is Used',
                body: isTagalog
                    ? 'Ang iyong datos ay ginagamit lamang para sa pagtaya sa panahon mula sa Open-Meteo, pagkwenta ng inaasahang presyo sa pamilihan, at pagtulong sa Municipal Agriculture Office ng Pagsanjan sa pagpaplano sa sektor ng agrikultura.'
                    : 'Your data is strictly utilized to process Open-Meteo weather forecasts, model estimated market prices, and assist the Pagsanjan Municipal Agriculture Office in local agricultural planning.',
              ),
              const SizedBox(height: 10),

              _PolicySection(
                title: isTagalog ? '3. Seguridad at Proteksyon' : '3. Data Protection & Security',
                body: isTagalog
                    ? 'Protektado ang lahat ng impormasyon ng magsasaka. Hindi kailanman ibinebenta o ibinabahagi ang iyong personal na datos sa mga ikatlong partido para sa komersyal na layunin.'
                    : 'All farmer records are protected under secure protocols. Personal details are never sold or shared with third parties for commercial gain.',
              ),
              const SizedBox(height: 10),

              _PolicySection(
                title: isTagalog ? '4. Karapatan ng Magsasaka' : '4. Farmer Rights',
                body: isTagalog
                    ? 'May karapatan ang magsasaka na tingnan, palitan, o ipabura ang kanyang datos anumang oras sa pamamagitan ng pag-aayos sa profile o pakikipag-ugnayan sa Municipal Agriculture Office.'
                    : 'Farmers maintain full rights to review, update, or request deletion of their profile records anytime through the app or by contacting the Municipal Agriculture Office.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
          onPressed: () => Navigator.pop(context),
          child: Text(isTagalog ? 'Naiintindihan Ko' : 'I Understand'),
        ),
      ],
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        Text(body, style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87)),
      ],
    );
  }
}

// ==========================================
// LOGIN SCREEN (Triggered on Logout)
// ==========================================

class _LoginScreen extends StatefulWidget {
  final DashboardProvider p;
  const _LoginScreen({required this.p});

  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final _phoneCtrl = TextEditingController(text: '+63 912 345 6789');
  final _pinCtrl = TextEditingController(text: '1234');

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _login() {
    widget.p.login();
  }

  @override
  Widget build(BuildContext context) {
    final isTagalog = widget.p.isTagalog;
    return Scaffold(
      backgroundColor: AppColors.paddy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PagriLogo(height: 100),
                const SizedBox(height: 20),
                const Text(
                  'PAGRI',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: 2, color: AppColors.leaf),
                ),
                Text(
                  isTagalog ? 'Portal ng Magsasaka ng Pagsanjan' : 'Pagsanjan Farmer Portal',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTagalog ? 'Mag-login sa Portal' : 'Sign In to Portal',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isTagalog
                              ? 'Ipasok ang numero ng telepono at PIN upang magpatuloy.'
                              : 'Enter your phone number and security PIN to continue.',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.leaf),
                            labelText: isTagalog ? 'Numero ng Telepono' : 'Phone Number',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _pinCtrl,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.leaf),
                            labelText: isTagalog ? '4-Digit PIN Passcode' : '4-Digit PIN Passcode',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.leaf,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _login,
                            icon: const Icon(Icons.login_rounded),
                            label: Text(
                              isTagalog ? 'Mag-login' : 'Sign In',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
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
