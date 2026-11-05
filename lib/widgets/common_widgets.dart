import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';

/// Marahang lumilitaw (fade + bahagyang slide) - may pagkakasunod-sunod.
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
    Future.delayed(Duration(milliseconds: 70 * widget.index), () {
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
        position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Shared scrolling list used by every tab: pads, scrolls, and fades items in.
class AnimatedTabList extends StatelessWidget {
  final List<Widget> items;
  const AnimatedTabList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => FadeSlideIn(index: math.min(i, 6), child: items[i]),
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

/// "Frosted glass" na card: malabong salamin na may manipis na puting guhit at malambot na anino.
/// Nakikita nang bahagya ang burol sa likod nito.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tint;
  final double radius;
  final bool blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.tint,
    this.radius = 24,
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    Widget inner = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (tint ?? Colors.white).withValues(alpha: 0.80),
            Colors.white.withValues(alpha: 0.58),
          ],
        ),
        borderRadius: r,
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.2),
      ),
      child: child,
    );
    if (blur) {
      inner = ClipRRect(
        borderRadius: r,
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: inner),
      );
    }
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: const [BoxShadow(color: Color(0x1F1B5E20), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: inner,
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
            Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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
      Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      Text(subtitle, style: const TextStyle(color: AppColors.muted)),
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
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const PagriLogo(height: 90),
        const SizedBox(height: 24),
        const CircularProgressIndicator(color: AppColors.leaf),
        const SizedBox(height: 16),
        Text(t.loadingWeather, style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
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
          const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
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