import 'package:flutter/material.dart';

import '../../../dashboard_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../widgets/common_widgets.dart';
import '../dialogs/privacy_policy_dialog.dart';

class SettingsTab extends StatelessWidget {
  final DashboardProvider p;
  const SettingsTab({super.key, required this.p});

  void _showPrivacyPolicy(BuildContext context) =>
      showDialog(context: context, builder: (_) => const PrivacyPolicyDialog());

  void _showHowToUse(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final steps = [t.howTo1, t.howTo2, t.howTo3, t.howTo4, t.howTo5];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.menu_book_rounded, color: AppColors.leaf),
          const SizedBox(width: 8),
          Flexible(child: Text(t.howToUse, style: const TextStyle(fontWeight: FontWeight.w900))),
        ]),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.leaf,
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(steps[i], style: const TextStyle(height: 1.35))),
                ]),
              ),
          ]),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.close),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.logout_rounded, color: Colors.redAccent),
          const SizedBox(width: 8),
          Text(t.logout),
        ]),
        content: Text(t.logoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.pop(ctx);
              p.logout();
            },
            child: Text(t.logoutButton),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.leaf),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final profile = p.profile;

    return AnimatedTabList(items: [
      TabHeader(title: t.appSettings, subtitle: t.appSettingsSub),
      const SizedBox(height: 16),

      // Account details (view only - galing sa admin)
      SectionTitle(icon: Icons.manage_accounts_rounded, text: t.accountDetails),
      Card(
        child: Column(children: [
          _info(Icons.person_rounded, t.farmerName, profile?.name ?? '-'),
          const Divider(height: 1, indent: 56),
          _info(Icons.location_on_rounded, t.barangay, profile == null ? '-' : '${profile.barangay}, Pagsanjan'),
          const Divider(height: 1, indent: 56),
          _info(Icons.cake_rounded, t.birthday, p.birthday),
          const Divider(height: 1, indent: 56),
          _info(Icons.square_foot_rounded, t.landSize, '${profile?.landSizeHectares ?? 0} ${t.hectares}'),
          const Divider(height: 1, indent: 56),
          _info(Icons.phone_android_rounded, t.phoneNumber, p.phoneNumber),
        ]),
      ),
      const SizedBox(height: 18),

      // Display - laki ng teksto
      SectionTitle(
        icon: Icons.text_fields_rounded,
        text: t.displaySettings,
        subtitle: t.displaySettingsSub,
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.textSize, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<double>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 1.0, label: Text(t.textSizeNormal)),
                  ButtonSegment(value: 1.15, label: Text(t.textSizeLarge)),
                  ButtonSegment(value: 1.3, label: Text(t.textSizeXLarge)),
                ],
                selected: {p.textScale},
                onSelectionChanged: (s) => p.setTextScale(s.first),
              ),
            ),
            const SizedBox(height: 12),
            Text(t.textSizeSample, style: const TextStyle(color: Colors.black54)),
          ]),
        ),
      ),
      const SizedBox(height: 18),

      // Tulong at suporta
      SectionTitle(
        icon: Icons.support_agent_rounded,
        text: t.helpSupport,
        subtitle: t.helpSupportSub,
      ),
      Card(
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: AppColors.leaf),
            title: Text(t.howToUse, style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showHowToUse(context),
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.account_balance_rounded, color: AppColors.leaf),
            title: Text(t.contactOffice, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(t.contactOfficeSub),
            isThreeLine: true,
          ),
        ]),
      ),
      const SizedBox(height: 18),

      // Privacy
      SectionTitle(icon: Icons.privacy_tip_rounded, text: t.privacyPolicy),
      Card(
        color: AppColors.mint.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.security_rounded, color: AppColors.leaf),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  t.privacySystemName,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              t.privacySummary,
              style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.leaf), backgroundColor: Colors.white),
                onPressed: () => _showPrivacyPolicy(context),
                icon: const Icon(Icons.description_rounded, color: AppColors.leaf, size: 18),
                label: Text(
                  t.readFullPolicy,
                  style: const TextStyle(color: AppColors.leaf, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 18),

      // Tungkol sa app
      SectionTitle(icon: Icons.info_outline_rounded, text: t.aboutApp),
      Card(
        child: ListTile(
          leading: const PagriLogo(height: 32),
          title: const Text('PAGRI', style: TextStyle(fontWeight: FontWeight.w900)),
          subtitle: Text('${t.appSubtitle}\n${t.appVersion}'),
          isThreeLine: true,
        ),
      ),
      const SizedBox(height: 18),

      // Log out
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
                t.logout,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }
}