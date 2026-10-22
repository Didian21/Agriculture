import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../main.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.privacy_tip_rounded, color: AppColors.leaf, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              t.privacyPolicy,
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
                t.privacySubtitle,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.leaf),
              ),
              const SizedBox(height: 12),
              _PolicySection(title: t.policy1Title, body: t.policy1Body),
              const SizedBox(height: 10),
              _PolicySection(title: t.policy2Title, body: t.policy2Body),
              const SizedBox(height: 10),
              _PolicySection(title: t.policy3Title, body: t.policy3Body),
              const SizedBox(height: 10),
              _PolicySection(title: t.policy4Title, body: t.policy4Body),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
          onPressed: () => Navigator.pop(context),
          child: Text(t.understand),
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