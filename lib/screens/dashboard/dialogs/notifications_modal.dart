import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_data.dart';
import '../../../dashboard_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';

void showNotificationsModal(BuildContext context, DashboardProvider p) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _NotificationsSheet(p: p),
  );
}

class _NotificationsSheet extends StatelessWidget {
  final DashboardProvider p;
  const _NotificationsSheet({required this.p});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final timeFmt = DateFormat.MMMd(locale).add_jm();

    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        final items = p.notifications;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(children: [
                Expanded(
                  child: Text(
                    t.notifications,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                if (p.unreadNotificationCount > 0)
                  TextButton(
                    onPressed: p.markAllNotificationsRead,
                    child: Text(t.markAllRead, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
            ),
            const Divider(height: 1),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(t.noNotifications, style: const TextStyle(color: Colors.black54)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final n = items[i];
                    return ListTile(
                      onTap: () => p.markNotificationRead(n.id),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.mint,
                        child: Icon(n.icon, color: AppColors.leaf),
                      ),
                      title: Text(
                        t.notifTitle(n),
                        style: TextStyle(
                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${t.notifMessage(n)}\n${timeFmt.format(n.time)}',
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                      isThreeLine: true,
                      trailing: n.isRead
                          ? null
                          : const Icon(Icons.circle, size: 10, color: Colors.redAccent),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }
}