import 'package:flutter/material.dart';

import '../../../dashboard_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../services/account_service.dart';
import '../../../services/supabase_service.dart';
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
              Navigator.pushReplacementNamed(context, '/');
            },
            child: Text(t.logoutButton),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text('Burahin ang Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sigurado ka bang gusto mong burahin nang tuluyan ang iyong account?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Babala: Mabubura nang tuluyan ang iyong profile at mga impormasyon sa Supabase cloud. Hindi na ito maibabalik.',
                      style: TextStyle(fontSize: 12, color: Colors.red, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              p.logout();
              Navigator.pushReplacementNamed(context, '/');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Matagumpay na nabura ang iyong account.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Oo, Burahin Na'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, DashboardProvider p) {
    final nameCtrl = TextEditingController(text: p.profile?.name ?? '');
    String selectedBrgy = p.profile?.barangay ?? 'Biñan';
    final phoneCtrl = TextEditingController(text: p.phoneNumber);
    final birthdayCtrl = TextEditingController(text: p.birthday);
    final landCtrl = TextEditingController(text: p.profile?.landSizeHectares.toString() ?? '2.5');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.leaf, size: 28),
            SizedBox(width: 8),
            Text('Edit Farmer Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedBrgy,
                decoration: const InputDecoration(labelText: 'Barangay', border: OutlineInputBorder()),
                items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => selectedBrgy = val ?? 'Biñan',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: birthdayCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Birthday (MM/DD/YYYY)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded, color: AppColors.leaf),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000, 1, 1),
                        firstDate: DateTime(1940),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        birthdayCtrl.text = '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: landCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Land Area (Hectares)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.leaf),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              final newBday = birthdayCtrl.text.trim();
              final newLand = double.tryParse(landCtrl.text.trim()) ?? 2.5;

              if (newName.isNotEmpty) {
                p.updateProfileDetails(
                  name: newName,
                  barangay: selectedBrgy,
                  phone: newPhone,
                  birthday: newBday,
                  landSize: newLand,
                );

                try {
                  await SupabaseService.client.from('farmers').update({
                    'profile_name': newName,
                    'barangay': selectedBrgy,
                    'contact_number': newPhone,
                  }).eq('username', p.currentUsername);
                } catch (_) {}

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Save Changes'),
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

      Card(
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.manage_accounts_rounded, color: AppColors.leaf),
            title: Text(t.accountDetails, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            trailing: TextButton.icon(
              onPressed: () => _showEditProfileDialog(context, p),
              icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.leaf),
              label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const Divider(height: 1),
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

      // Log out & Delete Account
      Card(
        color: Colors.red[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[800],
                    side: BorderSide(color: Colors.red[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _confirmDeleteAccount(context),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text(
                    'Burahin ang Aking Account (Delete Account)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }
}