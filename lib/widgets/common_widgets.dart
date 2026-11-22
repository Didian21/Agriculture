import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

/// Payak na paglitaw: dahan-dahang fade lang (walang pagkakasunod-sunod).
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index; // hindi na ginagamit; pinanatili para hindi masira ang lumang tawag
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut), child: widget.child);
}

/// Shared scrolling list used by every tab: pads, scrolls, and fades items in.
class AnimatedTabList extends StatelessWidget {
  final List<Widget> items;
  final ScrollController? controller;
  const AnimatedTabList({super.key, required this.items, this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.s, AppSpace.l, AppSpace.xl),
      itemCount: items.length,
      itemBuilder: (_, i) => FadeSlideIn(child: items[i]),
    );
  }
}

/// Bahagyang lumiliit kapag pinindot - banayad na feedback.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Payak na card: puti, manipis na gilid, at halos walang anino. Ito ang iisang card ng buong app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;
  final double radius;
  final bool blur; // hindi na ginagamit; pinanatili para hindi masira ang lumang tawag

  const GlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.tint,
    this.radius = AppRadius.card,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: (tint ?? Colors.white).withValues(alpha: 0.96),
        borderRadius: r,
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0F1B5E20), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return PressableScale(onTap: onTap, child: content);
  }
}

/// Bilog na icon na may bahagyang kulay sa likod.
class IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBubble({super.key, required this.icon, this.color = AppColors.leaf, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Numerong dahan-dahang tumataas (count-up).
class CountUp extends StatelessWidget {
  final double value;
  final int decimals;
  final TextStyle style;
  final String prefix;
  final String suffix;

  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('$prefix${v.toStringAsFixed(decimals)}$suffix', style: style),
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
            Text(text, style: AppText.section),
            if (subtitle != null) Text(subtitle!, style: AppText.small),
          ]),
        ),
      ]),
    );
  }
}

/// Tab heading: big title + muted subtitle.
class TabHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const TabHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AppText.pageTitle),
      const SizedBox(height: 2),
      Text(subtitle, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
    ]);
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, this.color, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 4)],
        Flexible(
          child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ]),
    );
  }
}

class LoadingView extends StatelessWidget {
  final bool? isTagalog; // hindi na kailangan; pinanatili para hindi masira ang lumang tawag
  const LoadingView({super.key, this.isTagalog});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.l, AppSpace.xl, AppSpace.l, AppSpace.xl),
      children: [
        const Center(child: PagriLogo(height: 72)),
        const SizedBox(height: AppSpace.m),
        Center(child: Text(t.loadingWeather, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted))),
        const SizedBox(height: AppSpace.xl),
        const SkeletonList(count: 3),
      ],
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool? isTagalog; // hindi na kailangan; pinanatili para hindi masira ang lumang tawag
  const ErrorView({super.key, required this.message, required this.onRetry, this.isTagalog});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: StatusColor.warn.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off_rounded, size: 40, color: StatusColor.warn),
          ),
          const SizedBox(height: AppSpace.l),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.35)),
          const SizedBox(height: AppSpace.xl),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t.tryAgain),
          ),
        ]),
      ),
    );
  }
}

/// Kulay-abong hugis na dahan-dahang kumukurap habang naglo-load (mas maayos kaysa umiikot na bilog).
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius = 10});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFE3EDE0), const Color(0xFFF1F6EF), _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Skeleton ng isang card (pamagat at ilang linya).
class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 110});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpace.l),
      child: SizedBox(
        height: height,
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBox(height: 16, width: 140),
          SizedBox(height: AppSpace.m),
          SkeletonBox(height: 12),
          SizedBox(height: AppSpace.s),
          SkeletonBox(height: 12, width: 220),
        ]),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      for (var i = 0; i < count; i++) const Padding(padding: EdgeInsets.only(bottom: AppSpace.m), child: SkeletonCard()),
    ]);
  }
}

/// Walang laman na bahagi: maliit na larawan, maikling paliwanag, at (opsyonal) buton ng susunod na gagawin.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: AppColors.leaf.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.leaf, size: 28),
        ),
        const SizedBox(height: AppSpace.m),
        Text(title, textAlign: TextAlign.center, style: AppText.cardTitle),
        if (body != null) ...[
          const SizedBox(height: AppSpace.s),
          Text(body!, textAlign: TextAlign.center, style: AppText.small),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpace.l),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
            child: Text(actionLabel!),
          ),
        ],
      ]),
    );
  }
}

/// Maliit na error sa loob ng card, may buton na "Subukan ulit".
class InlineError extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  const InlineError({super.key, required this.message, required this.retryLabel, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, color: StatusColor.warn, size: 26),
      const SizedBox(height: AppSpace.s),
      Text(message, textAlign: TextAlign.center, style: AppText.small),
      TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 18), label: Text(retryLabel)),
    ]);
  }
}