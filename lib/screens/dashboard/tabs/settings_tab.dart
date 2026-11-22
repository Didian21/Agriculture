import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/tr.dart';
import '../../../dashboard_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../models/farm_store.dart';
import '../../../models/farmer.dart';
import '../../../services/account_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../farmer_login_screen.dart';
import '../dialogs/privacy_policy_dialog.dart';

/// Settings: profile, wika, laki ng teksto, mga abiso, tulong, data at pinagkukunan, privacy, tungkol, at log out.
class SettingsTab extends StatelessWidget {
  final DashboardProvider p;
  const SettingsTab({super.key, required this.p});

  void _showPrivacyPolicy(BuildContext context) => showDialog(context: context, builder: (_) => const PrivacyPolicyDialog());

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

  void _showGlossary(BuildContext context) {
    final tl = isTl(context);
    final items = <(String, String, String, String)>[
      ('Heat index', 'Heat index', 'Gaano kainit ang pakiramdam ng katawan, kasama ang halumigmig. Mas mapanganib sa kalusugan kaysa sa temperatura lang.',
      'How hot it feels to the body, including humidity. More dangerous to health than temperature alone.'),
      ('Yugto ng tanim', 'Crop stages', 'Mga bahagi ng paglaki: pagsibol, paglaki ng dahon (vegetative), pamumulaklak, pamumunga, at anihan.',
      'Parts of growth: germination, vegetative growth, flowering, fruiting and harvest.'),
      ('Hektarya (ha)', 'Hectare (ha)', 'Sukat ng lupa na 10,000 metro kuwadrado (100 m x 100 m). Ang 1,000 sq m ay 0.1 ha.',
      'A land measure of 10,000 square meters (100 m x 100 m). 1,000 sq m is 0.1 ha.'),
      ('Basal na abono', 'Basal fertilizer', 'Abonong inilalagay sa pagtatanim o ilang araw pagkatapos, bago lumaki ang halaman.',
      'Fertilizer applied at planting or a few days later, before the plant grows.'),
      ('Pre-harvest interval', 'Pre-harvest interval', 'Bilang ng araw na dapat hintayin pagkatapos mag-spray bago anihin. Nakasulat ito sa label ng pestisidyo.',
      'Days to wait after spraying before harvest. It is printed on the pesticide label.'),
      ('IPM', 'IPM', 'Integrated Pest Management: unahin ang natural at pang-iwas na paraan, at kemikal lang bilang huling paraan.',
      'Integrated Pest Management: use natural and preventive methods first, chemicals only as a last resort.'),
      ('MAO / FPA', 'MAO / FPA', 'MAO: Municipal Agriculture Office ng Pagsanjan. FPA: Fertilizer and Pesticide Authority na nagrerehistro ng mga abono at pestisidyo.',
      'MAO: Pagsanjan Municipal Agriculture Office. FPA: Fertilizer and Pesticide Authority, which registers fertilizers and pesticides.'),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            children: [
              Text(tr(ctx, 'Paliwanag ng mga termino', 'Glossary'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              for (final g in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tl ? g.$1 : g.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.leaf)),
                    const SizedBox(height: 2),
                    Text(tl ? g.$3 : g.$4, style: const TextStyle(fontSize: 13, height: 1.4)),
                  ]),
                ),
            ],
          ),
        ),
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
            onPressed: () async {
              Navigator.pop(ctx);
              await p.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => FarmerLoginScreen(p: p)),
                  (route) => false,
                );
              }
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

  void _showEditProfileDialog(BuildContext context, DashboardProvider p) {
    final accountService = Provider.of<AccountService>(context, listen: false);
    final currentFarmer = accountService.farmers.firstWhere(
      (f) => f.username == p.currentUsername || f.contactNumber == p.phoneNumber,
      orElse: () => Farmer(
        id: 'CURRENT',
        username: p.currentUsername ?? 'farmer',
        password: 'password123',
        profileName: p.profile?.name ?? 'Juan Dela Cruz',
        barangay: p.profile?.barangay ?? 'Biñan',
        contactNumber: p.phoneNumber,
      ),
    );

    final nameCtrl = TextEditingController(text: currentFarmer.profileName);
    final phoneCtrl = TextEditingController(text: currentFarmer.contactNumber);
    final passCtrl = TextEditingController();
    String selectedBrgy = currentFarmer.barangay;
    bool obscurePass = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF166534).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF166534)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr(ctx, 'Baguhin ang Profile & Password', 'Edit Profile & Password'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: tr(ctx, 'Buong Pangalan', 'Full Name'),
                      prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF166534)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: AccountService.pagsanjanBarangays.contains(selectedBrgy) ? selectedBrgy : AccountService.pagsanjanBarangays.first,
                    decoration: InputDecoration(
                      labelText: 'Barangay',
                      prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF166534)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (val) => setDialogState(() => selectedBrgy = val ?? 'Biñan'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: tr(ctx, 'Numero ng Telepono', 'Phone Number'),
                      prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF166534)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: tr(ctx, 'Bagong Password (Opsyonal)', 'New Password (Optional)'),
                      prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF166534)),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePass ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      helperText: tr(ctx, 'Iwang blangko kung ayaw baguhin', 'Leave blank to keep current password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr(ctx, 'Kanselahin', 'Cancel'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(tr(ctx, 'I-save sa Supabase', 'Save to Supabase'), style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                final newPhone = phoneCtrl.text.trim();
                final newPass = passCtrl.text.trim();

                if (newName.isEmpty) return;

                await accountService.updateFarmer(
                  currentFarmer.id,
                  profileName: newName,
                  barangay: selectedBrgy,
                  contactNumber: newPhone.isEmpty ? currentFarmer.contactNumber : newPhone,
                  organization: currentFarmer.organization,
                  status: currentFarmer.status,
                  password: newPass.isNotEmpty ? newPass : null,
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr(context, 'Matagumpay na na-update ang profile at password sa Supabase!', 'Successfully updated profile and password in Supabase!'),
                      ),
                      backgroundColor: const Color(0xFF166534),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final profile = p.profile;
    final name = profile?.name ?? '-';
    final initial = name.trim().isNotEmpty && name != '-' ? name.trim()[0].toUpperCase() : 'P';

    return AnimatedTabList(items: [
      TabHeader(title: t.appSettings, subtitle: t.appSettingsSub),
      const SizedBox(height: 16),

      // Profile
      GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF166534),
                child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(profile == null ? '-' : '${profile.barangay}, Pagsanjan, Laguna', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Text(p.phoneNumber, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF166534),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF166534), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => _showEditProfileDialog(context, p),
                icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                label: Text(
                  tr(context, 'Baguhin ang Profile / Password', 'Edit Profile / Change Password'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(children: [
          _info(Icons.cake_rounded, t.birthday, p.birthday),
          const Divider(height: 1, indent: 56),
          ListenableBuilder(
            listenable: FarmStore.instance,
            builder: (context, _) {
              final store = FarmStore.instance;
              final total = store.totalHa;
              final used = store.usedHa();
              final n = store.profiles.length;
              final sub = total == null
                  ? tr(context, 'Wala pang nailalagay sa DSS.', 'Not entered in DSS yet.')
                  : n == 0
                  ? tr(context, 'Wala pang tanim na na-save sa DSS.', 'No crops saved in DSS yet.')
                  : tr(context, 'Gamit na ${used.toStringAsFixed(2)} ha sa $n tanim', '${used.toStringAsFixed(2)} ha used by $n crop${n == 1 ? '' : 's'}');
              return ListTile(
                leading: const Icon(Icons.square_foot_rounded, color: AppColors.leaf),
                title: Text(t.landSize, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(total == null ? sub : '${total.toStringAsFixed(2)} ${t.hectares}\n$sub'),
                isThreeLine: total != null,
              );
            },
          ),
        ]),
      ),
      const SizedBox(height: 18),

      // Wika
      SectionTitle(icon: Icons.translate_rounded, text: tr(context, 'Wika', 'Language')),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('Tagalog')),
                ButtonSegment(value: false, label: Text('English')),
              ],
              selected: {p.isTagalog},
              onSelectionChanged: (s) => p.setLanguage(s.first ? AppLanguage.tagalog : AppLanguage.english),
            ),
          ),
        ),
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
            leading: const Icon(Icons.spellcheck_rounded, color: AppColors.leaf),
            title: Text(tr(context, 'Paliwanag ng mga termino', 'Glossary'), style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(tr(context, 'Heat index, yugto ng tanim at iba pa', 'Heat index, crop stages and more')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showGlossary(context),
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

      // Data at pinagkukunan
      SectionTitle(
        icon: Icons.source_rounded,
        text: tr(context, 'Data at pinagkukunan', 'Data and sources'),
        subtitle: tr(context, 'Saan galing ang mga numero at ano ang hangganan nito', 'Where the numbers come from and their limits'),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SourceRow(Icons.cloud_rounded, tr(context, 'Panahon', 'Weather'), tr(context, 'Open-Meteo forecast. Tantiya lamang; para sa opisyal na babala, tingnan ang PAGASA.', 'Open-Meteo forecast. Estimates only; for official warnings, check PAGASA.')),
            _SourceRow(Icons.sell_rounded, tr(context, 'Presyo', 'Prices'), tr(context, 'Mula sa buwanang datos ng MAO kung mayroon; kung wala, tantiyang karaniwang presyo.', 'From monthly MAO data where available; otherwise a typical estimated price.')),
            _SourceRow(Icons.grass_rounded, tr(context, 'Abono at gastos', 'Fertilizer and cost'), tr(context, 'Tantiyang presyo ng abono sa Laguna at karaniwang gastos. Maaaring iba sa aktwal.', 'Estimated Laguna fertilizer prices and typical costs. May differ from actual.')),
            _SourceRow(Icons.bug_report_rounded, tr(context, 'Pestisidyo', 'Pesticides'), tr(context, 'Halimbawang aktibong sangkap lamang. Gumamit ng produktong rehistrado sa FPA at sundin ang label.', 'Example active ingredients only. Use FPA-registered products and follow the label.')),
            const SizedBox(height: 4),
            Text(
              tr(context, 'Ang ani, kita, mungkahing pananim at kalendaryo ay mga tantiya batay sa mga patakaran ng app, hindi garantiya. Kumpirmahin sa MAO ng Pagsanjan bago magdesisyon.',
                  'Yield, income, crop recommendations and the calendar are estimates from the app\'s rules, not guarantees. Confirm with the Pagsanjan MAO before deciding.'),
              style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
          ]),
        ),
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
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red[700],
            side: BorderSide(color: Colors.red[200]!),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: Text(t.logout, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

class _SourceRow extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _SourceRow(this.icon, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.leaf),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 1),
            Text(body, style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35)),
          ]),
        ),
      ]),
    );
  }
}