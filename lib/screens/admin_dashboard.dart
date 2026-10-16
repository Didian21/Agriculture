import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/farmer.dart';
import '../services/account_service.dart';

class AdminLocale {
  final bool isTagalog;
  AdminLocale(this.isTagalog);

  String get adminTitle => isTagalog ? 'Portal ng Agrikultura (Admin)' : 'MAO Admin Portal';
  String get officeSubtitle => isTagalog ? 'Tanggapan ng Agrikultura ng Pagsanjan' : 'Municipal Agriculture Office (MAO)';
  String get location => 'Pagsanjan, Laguna';

  // Nav Items (WITHOUT NUMBERS)
  String get navDashboard => isTagalog ? 'Buod ng Dashboard' : 'Dashboard Summary';
  String get navFarmers => isTagalog ? 'Mga Magsasaka' : 'Farmer Records';
  String get navFarms => isTagalog ? 'Mga Sakahan' : 'Farm Records';
  String get navHistorical => isTagalog ? 'Nakaraang Datos' : 'Historical Data';
  String get navMap => isTagalog ? 'Mapang Interaktibo' : 'Interactive Map';
  String get navAccounts => isTagalog ? 'Mga Akawnt ng Farmer' : 'Farmer Accounts';
  String get navCrops => isTagalog ? 'Pangangailangan ng Tanim' : 'Crop Requirements';
  String get navModel => isTagalog ? 'ML Model Status' : 'Model Management';
  String get navAdminStaff => isTagalog ? 'Mga Admin at Staff' : 'Admin Accounts';
  String get navActivityLog => isTagalog ? 'Talaan ng Kilos (Log)' : 'Activity Log';
  String get navLogout => isTagalog ? 'Mag-logout (Exit)' : 'Logout';

  // Dashboard Overview
  String get execSummary => isTagalog ? 'BUOD NG PAMAMAHALA' : 'EXECUTIVE SUMMARY';
  String get agriOverview => isTagalog ? 'Pangkalahatang Tanaw sa Agrikultura' : 'Agricultural Overview';
  String get exportPdf => isTagalog ? 'Export PDF' : 'Export PDF';
  String get exportExcel => isTagalog ? 'Export Excel' : 'Export Excel';
  String get filterTitle => isTagalog ? 'Mga Filter (Barangay, Tanim, Panahon)' : 'Filters (Barangay, Crop, Period)';
  String get kpiFarmers => isTagalog ? 'Rehistradong Magsasaka' : 'Registered Farmers';
  String get kpiFarmArea => isTagalog ? 'Kabuuan ng Lupaing Sakahan' : 'Total Farm Area';
  String get kpiMlAccuracy => isTagalog ? 'Tumpak ng ML Prediction' : 'ML Prediction Accuracy';
  String get farmersPerBarangay => isTagalog ? 'Bilang ng Magsasaka Bawat Barangay' : 'Farmers per Barangay';
  String get areaPerCrop => isTagalog ? 'Lupaing Sakahan Bawat Uri ng Tanim' : 'Farm Area per Crop Type';
  String get historicalTrends => isTagalog ? 'Nakaraang Trend sa Ani at Presyo (MAO)' : 'Historical Production & Price Trends (MAO)';

  // Weather
  String get weatherTitle => isTagalog ? 'Ulat ng Panahon sa Agrikultura' : 'Pagsanjan Agricultural Weather';
  String get liveUpdated => isTagalog ? 'BAGO AT LIVE' : 'LIVE UPDATED';
  String get weatherForecast => isTagalog ? '5-Araw na Ulat ng Panahon sa Sakahan' : '5-Day Agricultural Weather Forecast';
  String get weatherAdvisory => isTagalog ? '🌾 Payo: Angkop ang panahon para sa pagpapataba' : '🌾 Advisory: Favorable for fertilizer application';

  // Farmer Records
  String get farmerDirTitle => isTagalog ? 'Direktoryo ng mga Magsasaka' : 'Farmer Records Management';
  String get addFarmer => isTagalog ? 'Magdagdag ng Magsasaka' : 'Add Farmer';
  String get searchFarmerPlaceholder => isTagalog ? 'Magsaliksik ng pangalan, username, o samahan...' : 'Search farmer name, username, or association...';

  // Farm Records
  String get farmRecordsTitle => isTagalog ? 'Pamamahala ng Lupa at Tanim' : 'Farm Records Management';
  String get addFarmRecord => isTagalog ? 'Magdagdag ng Sakahan' : 'Add Farm Record';

  // Historical Data
  String get historicalTitle => isTagalog ? 'Mga Nakaraang Rekord ng MAO' : 'Historical Production & Price Data';
  String get uploadMaoRecord => isTagalog ? 'Mag-upload ng Rekord' : 'Upload MAO Record';

  // Interactive Map
  String get mapTitle => isTagalog ? 'Interaktibong Mapa ng mga Sakahan' : 'Interactive Farm Map (Pagsanjan)';
  String get registeredPins => isTagalog ? 'Mga Pin ng Rehistradong Sakahan' : 'Registered Farm Pins';

  // Farmer Accounts
  String get accountsTitle => isTagalog ? 'Pamamahala ng mga Akawnt ng Farmer' : 'Farmer Accounts Management';

  // Crop Requirements
  String get cropReqTitle => isTagalog ? 'Especipikasyon sa Pagtatanim' : 'Crop Planting Requirements';
  String get addCropSpecs => isTagalog ? 'Magdagdag ng Specs' : 'Add Crop Specs';

  // ML Model
  String get modelTitle => isTagalog ? 'Pamamahala sa ML Model at Accuracy' : 'ML Model Management & Accuracy';
  String get retrainModel => isTagalog ? 'Muling I-train ang ML Model' : 'Re-train ML Model';
  String get retrainingModel => isTagalog ? 'Sinasanay ang ML Model...' : 'Re-training ML Model...';

  // Admin Staff
  String get adminStaffTitle => isTagalog ? 'Mga Akawnt ng Admin at Tungkulin' : 'Admin Accounts & Staff Roles';
  String get addStaff => isTagalog ? 'Magdagdag ng Staff' : 'Add MAO Staff';

  // Activity Log
  String get activityLogTitle => isTagalog ? 'Talaan ng Kilos sa Sistema (Audit)' : 'Activity Log (System Audit Trail)';
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // 0..9 for the 10 main modules
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filters for Dashboard Summary
  String _selectedCropFilter = 'All';
  String _selectedBarangayFilter = 'All';
  String _selectedTimePeriodFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerExport(BuildContext context, String type, bool isTagalog) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTagalog
              ? 'Ginagawa at kino-kopya ang ulat sa $type para sa Pagsanjan MAO...'
              : 'Generating and downloading $type report for Pagsanjan MAO...',
        ),
        backgroundColor: const Color(0xFF0056B3),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AdminLocale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(locale.isTagalog ? 'Kumpirmahin ang Logout' : 'Confirm Logout'),
          ],
        ),
        content: Text(
          locale.isTagalog
              ? 'Sigurado ka bang gusto mong mag-logout sa Admin Portal?'
              : 'Are you sure you want to log out of the Admin Portal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/thank_you');
            },
            child: Text(locale.isTagalog ? 'Mag-logout' : 'Logout'),
          ),
        ],
      ),
    );
  }

  void _showSwitchStaffDialog(BuildContext context, AccountService service, AdminLocale locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.switch_account_rounded, color: Color(0xFF0056B3)),
            const SizedBox(width: 8),
            Text(locale.isTagalog ? 'Palitan ang Aktibong Staff' : 'Switch Active Staff Account'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.isTagalog
                    ? 'Pumili ng MAO staff member na kasalukuyang gumagamit ng portal. Lahat ng gagawing kilos (Add, Edit, Delete, Upload) ay mai-rerecord sa pangalan niya sa Activity Log.'
                    : 'Select the MAO staff member currently operating the portal. All actions (Add, Edit, Delete, Upload) will be attributed to them in the Activity Log.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...service.adminStaffList.map((staff) {
                final isSelected = service.activeStaff.id == staff.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? const Color(0xFF0056B3) : Colors.grey.shade300, width: isSelected ? 2 : 1),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? const Color(0xFF0056B3) : Colors.grey.shade200,
                      foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
                      child: Text(staff.name.isNotEmpty ? staff.name[0] : 'S'),
                    ),
                    title: Text(staff.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? const Color(0xFF0056B3) : Colors.black87)),
                    subtitle: Text('${staff.role} • @${staff.username}', style: const TextStyle(fontSize: 11)),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0056B3)) : null,
                    onTap: () {
                      service.switchActiveStaff(staff);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            locale.isTagalog
                                ? 'Pinalitan ang aktibong operator kay ${staff.name} (${staff.role})'
                                : 'Active session switched to ${staff.name} (${staff.role})',
                          ),
                          backgroundColor: const Color(0xFF0056B3),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.isTagalog ? 'Isara' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleExportButtons(BuildContext context, String moduleName, AdminLocale locale) {
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _triggerExport(context, '$moduleName (PDF)', locale.isTagalog),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
            side: const BorderSide(color: Color(0xFFDC2626)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
          label: Text(locale.exportPdf, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        OutlinedButton.icon(
          onPressed: () => _triggerExport(context, '$moduleName (Excel/CSV)', locale.isTagalog),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0284C7),
            side: const BorderSide(color: Color(0xFF0284C7)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.table_chart_rounded, size: 15),
          label: Text(locale.exportExcel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AccountService>(context);
    final isDark = service.isDarkMode;
    final isTagalog = service.isTagalog;
    final locale = AdminLocale(isTagalog);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;

    // SHADES OF BLUE COLOR PALETTE
    final bgColor = isDark ? const Color(0xFF0A111E) : const Color(0xFFF0F4F9);
    final sidebarBg = isDark ? const Color(0xFF081427) : const Color(0xFF0A2540);
    final cardBg = isDark ? const Color(0xFF121E31) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBorder = isDark ? const Color(0xFF1E2E4A) : const Color(0xFFD0E1F9);
    final primaryAccent = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0056B3);
    final secondaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);

    final sidebarContent = Container(
      width: 275,
      color: sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Branding Widget (Deep Blue Royal Gradient)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                    : [const Color(0xFF0056B3), const Color(0xFF0A2540)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF93C5FD), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.adminTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locale.location,
                        style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ACTIVE STAFF OPERATOR CARD (SWITCH ACCOUNT)
          InkWell(
            onTap: () => _showSwitchStaffDialog(context, service, locale),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFF60A5FA),
                    foregroundColor: Colors.white,
                    child: Text(
                      service.activeStaff.name.isNotEmpty ? service.activeStaff.name[0] : 'S',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.activeStaff.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          service.activeStaff.role,
                          style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.swap_vert_rounded, color: Color(0xFF93C5FD), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white12, height: 1),

          // Nav Items List (WITHOUT NUMBERS, BLUE ACCENTS)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _buildNavItem(icon: Icons.dashboard_rounded, label: locale.navDashboard, index: 0, isDark: isDark),
                _buildNavItem(icon: Icons.badge_rounded, label: locale.navFarmers, index: 1, isDark: isDark),
                _buildNavItem(icon: Icons.landscape_rounded, label: locale.navFarms, index: 2, isDark: isDark),
                _buildNavItem(icon: Icons.history_edu_rounded, label: locale.navHistorical, index: 3, isDark: isDark),
                _buildNavItem(icon: Icons.map_rounded, label: locale.navMap, index: 4, isDark: isDark),
                _buildNavItem(icon: Icons.manage_accounts_rounded, label: locale.navAccounts, index: 5, isDark: isDark),
                _buildNavItem(icon: Icons.eco_rounded, label: locale.navCrops, index: 6, isDark: isDark),
                _buildNavItem(icon: Icons.psychology_rounded, label: locale.navModel, index: 7, isDark: isDark),
                _buildNavItem(icon: Icons.supervisor_account_rounded, label: locale.navAdminStaff, index: 8, isDark: isDark),
                _buildNavItem(icon: Icons.receipt_long_rounded, label: locale.navActivityLog, index: 9, isDark: isDark),
              ],
            ),
          ),

          // PROMINENT LOGOUT BUTTON AT SIDEBAR BOTTOM
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context, locale),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(locale.navLogout, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );

    Widget mainContentArea;
    switch (_selectedIndex) {
      case 0:
        mainContentArea = _buildDashboardSummaryView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent, secondaryBlue);
        break;
      case 1:
        mainContentArea = _buildFarmerRecordsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 2:
        mainContentArea = _buildFarmRecordsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 3:
        mainContentArea = _buildHistoricalDataView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 4:
        mainContentArea = _buildInteractiveMapView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 5:
        mainContentArea = _buildFarmerAccountsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 6:
        mainContentArea = _buildCropRequirementsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 7:
        mainContentArea = _buildModelManagementView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 8:
        mainContentArea = _buildAdminAccountsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 9:
        mainContentArea = _buildActivityLogView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      default:
        mainContentArea = _buildDashboardSummaryView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent, secondaryBlue);
    }

    final topHeader = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('Pagri.jpg', width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF0056B3))),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locale.adminTitle,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                locale.officeSubtitle,
                style: TextStyle(color: subtextColor, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),

          // SWITCH STAFF ACCOUNT BUTTON IN HEADER
          InkWell(
            onTap: () => _showSwitchStaffDialog(context, service, locale),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.badge_rounded, size: 16, color: primaryAccent),
                  const SizedBox(width: 6),
                  Text(
                    'Operator: ${service.activeStaff.name.split(" ").first}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryAccent),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded, size: 18, color: primaryAccent),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // LANGUAGE TOGGLE BUTTON (English / Tagalog)
          InkWell(
            onTap: () => service.toggleLanguage(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(isTagalog ? '🇵🇭 Tagalog' : '🇺🇸 English', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryAccent)),
                  const SizedBox(width: 4),
                  Icon(Icons.swap_horiz_rounded, size: 16, color: primaryAccent),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // DARK / LIGHT MODE TOGGLE BUTTON
          IconButton(
            tooltip: isDark ? 'Switch to Light Blue Mode' : 'Switch to Dark Blue Mode',
            onPressed: () => service.toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : const Color(0xFF0056B3),
            ),
          ),
          const SizedBox(width: 8),

          IconButton(
            onPressed: () => _showCreatePostDialog(context, service, locale),
            icon: Icon(Icons.campaign_rounded, color: primaryAccent),
            tooltip: 'Post Announcement',
          ),
          const SizedBox(width: 10),

          // HEADER LOGOUT BUTTON
          IconButton(
            tooltip: locale.navLogout,
            onPressed: () => _confirmLogout(context, locale),
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
    );

    final fullBody = Column(
      children: [
        topHeader,
        Expanded(child: mainContentArea),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Row(
          children: [
            sidebarContent,
            Expanded(child: fullBody),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: sidebarBg,
          foregroundColor: Colors.white,
          title: Text(locale.adminTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _confirmLogout(context, locale),
            ),
          ],
        ),
        drawer: Drawer(child: sidebarContent),
        body: fullBody,
      );
    }
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required bool isDark}) {
    final isSelected = _selectedIndex == index;
    final activeBg = isDark ? const Color(0xFF2563EB).withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.22);
    final activeText = isDark ? const Color(0xFF60A5FA) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: activeText.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? activeText : Colors.white60, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeText : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  // ==========================================
  // MODULE 1: DASHBOARD SUMMARY (FULL EXPORT)
  // ==========================================
  Widget _buildDashboardSummaryView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
    Color secondaryBlue,
  ) {
    final farmers = service.farmers;
    final farms = service.farms;
    final historical = service.historicalRecords;

    // Apply Filters
    final filteredFarms = farms.where((f) {
      final matchesBarangay = _selectedBarangayFilter == 'All' || f.barangay == _selectedBarangayFilter;
      final matchesCrop = _selectedCropFilter == 'All' || f.cropType == _selectedCropFilter;
      return matchesBarangay && matchesCrop;
    }).toList();

    // Calculate Metrics
    final totalFarmersCount = farmers.length;
    final totalFarmArea = filteredFarms.fold(0.0, (sum, item) => sum + item.landAreaHectares);

    // Farmers per Barangay Map
    final Map<String, int> farmersPerBarangay = {};
    for (final f in farmers) {
      farmersPerBarangay[f.barangay] = (farmersPerBarangay[f.barangay] ?? 0) + 1;
    }

    // Farm Area per Crop Map
    final Map<String, double> areaPerCrop = {};
    for (final farm in filteredFarms) {
      areaPerCrop[farm.cropType] = (areaPerCrop[farm.cropType] ?? 0.0) + farm.landAreaHectares;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header & Full System Export Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locale.execSummary, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent, letterSpacing: 1.1)),
                  const SizedBox(height: 2),
                  Text(locale.agriOverview, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              _buildModuleExportButtons(context, 'Full Executive Summary', locale),
            ],
          ),
          const SizedBox(height: 18),

          // Filter Controls Card (Shades of Blue)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
              boxShadow: isDark ? [] : const [BoxShadow(color: Color(0x0A0056B3), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_alt_rounded, size: 18, color: primaryAccent),
                    const SizedBox(width: 6),
                    Text(locale.filterTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    // Barangay Filter
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        value: _selectedBarangayFilter,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Barangay',
                          labelStyle: TextStyle(color: subtextColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['All', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setState(() => _selectedBarangayFilter = val ?? 'All'),
                      ),
                    ),
                    // Crop Filter
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCropFilter,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Crop Type',
                          labelStyle: TextStyle(color: subtextColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['All', 'Rice', 'Prutas', 'Gulay'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => _selectedCropFilter = val ?? 'All'),
                      ),
                    ),
                    // Time Period Filter
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: _selectedTimePeriodFilter,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: locale.isTagalog ? 'Panahon' : 'Period',
                          labelStyle: TextStyle(color: subtextColor),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: ['All', '2026', '2025', 'Wet Season', 'Dry Season'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setState(() => _selectedTimePeriodFilter = val ?? 'All'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // KPI Cards (Shades of Blue Accent)
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: locale.kpiFarmers,
                  value: '$totalFarmersCount',
                  subtitle: locale.location,
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF0056B3),
                  cardBg: cardBg,
                  textColor: textColor,
                  cardBorder: cardBorder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: locale.kpiFarmArea,
                  value: '${totalFarmArea.toStringAsFixed(1)} ha',
                  subtitle: 'Active Land',
                  icon: Icons.landscape_rounded,
                  color: const Color(0xFF0284C7),
                  cardBg: cardBg,
                  textColor: textColor,
                  cardBorder: cardBorder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: locale.kpiMlAccuracy,
                  value: '${(100 - service.modelStatus.mape).toStringAsFixed(1)}%',
                  subtitle: 'MAPE: ${service.modelStatus.mape}%',
                  icon: Icons.psychology_rounded,
                  color: const Color(0xFF4F46E5),
                  cardBg: cardBg,
                  textColor: textColor,
                  cardBorder: cardBorder,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Weather Card (Deep Sapphire Sky Blue Gradient)
          _buildWeatherCard(locale, isDark, cardBg, textColor, primaryAccent),
          const SizedBox(height: 20),

          // Data Breakdown Section (Shades of Blue)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farmers per Barangay
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.farmersPerBarangay, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                      const SizedBox(height: 12),
                      if (farmersPerBarangay.isEmpty)
                        Text('No records found', style: TextStyle(color: subtextColor))
                      else
                        ...farmersPerBarangay.entries.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Expanded(child: Text(entry.key, style: TextStyle(fontSize: 13, color: textColor))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: primaryAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                child: Text('${entry.value} ${locale.isTagalog ? "magsasaka" : "farmers"}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Total Farm Area per Crop Type
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.areaPerCrop, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                      const SizedBox(height: 12),
                      if (areaPerCrop.isEmpty)
                        Text('No records found', style: TextStyle(color: subtextColor))
                      else
                        ...areaPerCrop.entries.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Expanded(child: Text(entry.key, style: TextStyle(fontSize: 13, color: textColor))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                child: Text('${entry.value.toStringAsFixed(1)} ha', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Historical Production & Price Trends
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.historicalTrends, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Crop', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Period', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Production (MT)', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Avg Price (PHP/kg)', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Uploaded By', style: TextStyle(color: subtextColor))),
                    ],
                    rows: historical.map((h) => DataRow(
                      cells: [
                        DataCell(Text(h.crop, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                        DataCell(Text('${h.month} ${h.year}', style: TextStyle(color: textColor))),
                        DataCell(Text('${h.productionMT} MT', style: TextStyle(color: textColor))),
                        DataCell(Text('₱${h.pricePerKg.toStringAsFixed(2)}', style: TextStyle(color: textColor))),
                        DataCell(Text(h.uploadedBy, style: TextStyle(color: textColor))),
                      ],
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(AdminLocale locale, bool isDark, Color cardBg, Color textColor, Color primaryAccent) {
    final forecast = [
      {'day': 'Mon', 'temp': '30°C', 'icon': Icons.wb_sunny_rounded, 'color': Colors.amber, 'condition': 'Sunny'},
      {'day': 'Tue', 'temp': '28°C', 'icon': Icons.grain_rounded, 'color': Colors.lightBlueAccent, 'condition': 'Light Rain'},
      {'day': 'Wed', 'temp': '29°C', 'icon': Icons.cloud_rounded, 'color': Colors.grey, 'condition': 'Partly Cloudy'},
      {'day': 'Thu', 'temp': '31°C', 'icon': Icons.wb_sunny_rounded, 'color': Colors.amber, 'condition': 'Clear Sky'},
      {'day': 'Fri', 'temp': '27°C', 'icon': Icons.water_drop_rounded, 'color': Colors.blueAccent, 'condition': 'Showers'},
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF0056B3), const Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_cloudy_rounded, color: Color(0xFF93C5FD), size: 30),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.weatherTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${locale.location} (14.2717° N, 121.4553° E)', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(locale.liveUpdated, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('29°C', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Partly Cloudy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Feels like 32°C • Wind: 14 km/h ENE', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: 16,
                children: [
                  _buildWeatherInfoBadge(Icons.water_drop_rounded, 'Humidity', '76%'),
                  _buildWeatherInfoBadge(Icons.thunderstorm_rounded, 'Rainfall', '12 mm'),
                  _buildWeatherInfoBadge(Icons.eco_rounded, 'Soil Temp', '26.5°C'),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(locale.weatherForecast, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(12)),
                child: Text(locale.weatherAdvisory, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: forecast.map((f) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(f['day'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Icon(f['icon'] as IconData, color: f['color'] as Color, size: 22),
                    const SizedBox(height: 4),
                    Text(f['temp'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(f['condition'] as String, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfoBadge(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF93C5FD), size: 18),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color textColor,
    required Color cardBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            foregroundColor: color,
            radius: 22,
            child: Icon(icon, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 2: FARMER RECORDS (WITH MODULE EXPORT)
  // ==========================================
  Widget _buildFarmerRecordsView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final farmers = service.farmers.where((f) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = f.profileName.toLowerCase().contains(query) ||
                           f.username.toLowerCase().contains(query) ||
                           f.organization.toLowerCase().contains(query);
      final matchesBarangay = _selectedBarangayFilter == 'All' || f.barangay == _selectedBarangayFilter;
      return matchesQuery && matchesBarangay;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DIRECTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.farmerDirTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildModuleExportButtons(context, 'Farmer Records', locale),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFarmerDialog(context, service),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(locale.addFarmer, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Barangay Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: locale.searchFarmerPlaceholder,
                    hintStyle: TextStyle(color: subtextColor, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: subtextColor),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  value: _selectedBarangayFilter,
                  dropdownColor: cardBg,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Filter Barangay',
                    labelStyle: TextStyle(color: subtextColor),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cardBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['All', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) => setState(() => _selectedBarangayFilter = val ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Farmers Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: farmers.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final farmer = farmers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryAccent.withValues(alpha: 0.15),
                      foregroundColor: primaryAccent,
                      child: Text(farmer.profileName.isNotEmpty ? farmer.profileName[0] : 'F'),
                    ),
                    title: Text(farmer.profileName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('Barangay: ${farmer.barangay} • Contact: ${farmer.contactNumber}\nAssoc: ${farmer.organization}', style: TextStyle(color: subtextColor)),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                          onPressed: () => _showEditFarmerDialog(context, service, farmer),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                          onPressed: () => service.deleteFarmer(farmer.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFarmerDialog(BuildContext context, AccountService service) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final orgCtrl = TextEditingController();
    String selectedBrgy = 'Biñan';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Farmer Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Personal Name')),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              DropdownButtonFormField<String>(
                value: selectedBrgy,
                decoration: const InputDecoration(labelText: 'Barangay'),
                items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => selectedBrgy = val ?? 'Biñan',
              ),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Details')),
              TextField(controller: orgCtrl, decoration: const InputDecoration(labelText: 'Association / Org Membership')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && userCtrl.text.isNotEmpty) {
                service.addFarmer(
                  username: userCtrl.text,
                  password: passCtrl.text.isEmpty ? 'password123' : passCtrl.text,
                  profileName: nameCtrl.text,
                  barangay: selectedBrgy,
                  contactNumber: contactCtrl.text.isEmpty ? 'N/A' : contactCtrl.text,
                  organization: orgCtrl.text.isEmpty ? 'Independent' : orgCtrl.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditFarmerDialog(BuildContext context, AccountService service, Farmer farmer) {
    final nameCtrl = TextEditingController(text: farmer.profileName);
    final contactCtrl = TextEditingController(text: farmer.contactNumber);
    final orgCtrl = TextEditingController(text: farmer.organization);
    String selectedBrgy = farmer.barangay;
    String selectedStatus = farmer.status;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Farmer Record (${farmer.username})'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              DropdownButtonFormField<String>(
                value: selectedBrgy,
                decoration: const InputDecoration(labelText: 'Barangay'),
                items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => selectedBrgy = val ?? farmer.barangay,
              ),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Details')),
              TextField(controller: orgCtrl, decoration: const InputDecoration(labelText: 'Association Membership')),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Active', 'Pending', 'Deactivated'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => selectedStatus = val ?? farmer.status,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              service.updateFarmer(
                farmer.id,
                profileName: nameCtrl.text,
                barangay: selectedBrgy,
                contactNumber: contactCtrl.text,
                organization: orgCtrl.text,
                status: selectedStatus,
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 3: FARM RECORDS (WITH MODULE EXPORT)
  // ==========================================
  Widget _buildFarmRecordsView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final farms = service.farms;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAND & CROPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.farmRecordsTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildModuleExportButtons(context, 'Farm Records', locale),
                  ElevatedButton.icon(
                    onPressed: () => _showAddFarmDialog(context, service),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: Text(locale.addFarmRecord, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: farms.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final farm = farms[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryAccent.withValues(alpha: 0.15),
                      foregroundColor: primaryAccent,
                      child: const Icon(Icons.eco_rounded),
                    ),
                    title: Text('${farm.farmerName} (${farm.cropType})', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('Location: ${farm.locationName}, ${farm.barangay}\nArea: ${farm.landAreaHectares} ha • Tenure: ${farm.tenureStatus} • Pin: [${farm.latitude}, ${farm.longitude}]', style: TextStyle(color: subtextColor)),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                      onPressed: () => service.deleteFarmRecord(farm.id),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFarmDialog(BuildContext context, AccountService service) {
    String selectedFarmerId = service.farmers.isNotEmpty ? service.farmers.first.id : '';
    final locationCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: '14.2717');
    final lonCtrl = TextEditingController(text: '121.4553');
    String selectedTenure = 'Owner';
    String selectedCrop = 'Rice';
    String selectedBrgy = 'Biñan';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Farm Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedFarmerId,
                decoration: const InputDecoration(labelText: 'Select Farmer'),
                items: service.farmers.map((f) => DropdownMenuItem(value: f.id, child: Text(f.profileName))).toList(),
                onChanged: (val) => selectedFarmerId = val ?? '',
              ),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Farm Location / Sitio')),
              DropdownButtonFormField<String>(
                value: selectedBrgy,
                decoration: const InputDecoration(labelText: 'Barangay'),
                items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => selectedBrgy = val ?? 'Biñan',
              ),
              TextField(controller: areaCtrl, decoration: const InputDecoration(labelText: 'Land Area (Hectares)'), keyboardType: TextInputType.number),
              DropdownButtonFormField<String>(
                value: selectedTenure,
                decoration: const InputDecoration(labelText: 'Land Tenure Status'),
                items: ['Owner', 'Tenant', 'Lease', 'CLT'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => selectedTenure = val ?? 'Owner',
              ),
              DropdownButtonFormField<String>(
                value: selectedCrop,
                decoration: const InputDecoration(labelText: 'Crop Type'),
                items: ['Rice', 'Prutas', 'Gulay'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => selectedCrop = val ?? 'Rice',
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitude'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'Longitude'))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final farmer = service.farmers.firstWhere((f) => f.id == selectedFarmerId, orElse: () => service.farmers.first);
              service.addFarmRecord(
                farmerId: farmer.id,
                farmerName: farmer.profileName,
                locationName: locationCtrl.text,
                latitude: double.tryParse(latCtrl.text) ?? 14.2717,
                longitude: double.tryParse(lonCtrl.text) ?? 121.4553,
                landAreaHectares: double.tryParse(areaCtrl.text) ?? 1.0,
                tenureStatus: selectedTenure,
                cropType: selectedCrop,
                barangay: selectedBrgy,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 4: HISTORICAL DATA (WITH MODULE EXPORT)
  // ==========================================
  Widget _buildHistoricalDataView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final records = service.historicalRecords;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MAO DATASET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.historicalTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildModuleExportButtons(context, 'Historical Data', locale),
                  ElevatedButton.icon(
                    onPressed: () => _showUploadCsvDialog(context, service),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(locale.uploadMaoRecord, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Crop', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Year', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Month', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Production (MT)', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Price / kg (PHP)', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Uploaded By', style: TextStyle(color: subtextColor))),
                      DataColumn(label: Text('Actions', style: TextStyle(color: subtextColor))),
                    ],
                    rows: records.map((r) => DataRow(
                      cells: [
                        DataCell(Text(r.crop, style: TextStyle(fontWeight: FontWeight.bold, color: textColor))),
                        DataCell(Text('${r.year}', style: TextStyle(color: textColor))),
                        DataCell(Text(r.month, style: TextStyle(color: textColor))),
                        DataCell(Text('${r.productionMT} MT', style: TextStyle(color: textColor))),
                        DataCell(Text('₱${r.pricePerKg.toStringAsFixed(2)}', style: TextStyle(color: textColor))),
                        DataCell(Text(r.uploadedBy, style: TextStyle(color: textColor))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => service.deleteHistoricalRecord(r.id),
                          ),
                        ),
                      ],
                    )).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadCsvDialog(BuildContext context, AccountService service) {
    final cropCtrl = TextEditingController(text: 'Rice');
    final yearCtrl = TextEditingController(text: '2026');
    final monthCtrl = TextEditingController(text: 'February');
    final prodCtrl = TextEditingController(text: '500.0');
    final priceCtrl = TextEditingController(text: '24.50');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload / Add MAO Historical Record'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Validated input format for data cleaning:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(controller: cropCtrl, decoration: const InputDecoration(labelText: 'Crop Name')),
              TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Year'), keyboardType: TextInputType.number),
              TextField(controller: monthCtrl, decoration: const InputDecoration(labelText: 'Month')),
              TextField(controller: prodCtrl, decoration: const InputDecoration(labelText: 'Production (Metric Tons)'), keyboardType: TextInputType.number),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price per KG (PHP)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              service.addHistoricalRecord(
                crop: cropCtrl.text,
                year: int.tryParse(yearCtrl.text) ?? 2026,
                month: monthCtrl.text,
                productionMT: double.tryParse(prodCtrl.text) ?? 100.0,
                pricePerKg: double.tryParse(priceCtrl.text) ?? 20.0,
                uploadedBy: service.activeUserName,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Historical record validated and saved!')),
              );
            },
            child: const Text('Validate & Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 5: INTERACTIVE MAP (WITH MODULE EXPORT)
  // ==========================================
  Widget _buildInteractiveMapView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final farms = service.farms;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GIS & WEATHER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.mapTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              _buildModuleExportButtons(context, 'Farms Map List', locale),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBAE6FD)),
              ),
              child: Stack(
                children: [
                  // Simulated Visual Map Representation of Pagsanjan
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 80, color: isDark ? const Color(0xFF2563EB) : const Color(0xFF38BDF8)),
                        const SizedBox(height: 8),
                        Text(
                          'PAGSANJAN FARMS MAP VIEW',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryAccent),
                        ),
                        Text('Coordinates: 14.2717° N, 121.4553° E', style: TextStyle(color: subtextColor, fontSize: 12)),
                      ],
                    ),
                  ),

                  // Interactive Farm Pins List overlay
                  Positioned(
                    left: 20,
                    top: 20,
                    bottom: 20,
                    width: 300,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorder),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(locale.registeredPins, style: TextStyle(fontWeight: FontWeight.bold, color: primaryAccent)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: farms.length,
                              itemBuilder: (context, index) {
                                final farm = farms[index];
                                return Card(
                                  color: isDark ? const Color(0xFF1E2E4A) : Colors.white,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: ListTile(
                                    leading: const Icon(Icons.location_on_rounded, color: Colors.redAccent),
                                    title: Text(farm.farmerName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                                    subtitle: Text('${farm.cropType} • ${farm.barangay}', style: TextStyle(color: subtextColor)),
                                    onTap: () => _showFarmWeatherModal(context, farm, locale, cardBg, textColor),
                                  ),
                                );
                              },
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
        ],
      ),
    );
  }

  void _showFarmWeatherModal(BuildContext context, FarmRecord farm, AdminLocale locale, Color cardBg, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.redAccent, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${farm.farmerName}\'s Farm (${farm.locationName})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text('Barangay: ${farm.barangay}', style: TextStyle(color: textColor)),
            Text('Crop Type: ${farm.cropType}', style: TextStyle(color: textColor)),
            Text('Land Area: ${farm.landAreaHectares} Hectares', style: TextStyle(color: textColor)),
            Text('Tenure Status: ${farm.tenureStatus}', style: TextStyle(color: textColor)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 32),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pagsanjan Real-Time Weather', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                      Text('Temp: 29°C • Humidity: 78% • Partly Cloudy', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MODULE 6: FARMER ACCOUNTS (WITH MODULE EXPORT)
  // ==========================================
  Widget _buildFarmerAccountsView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final farmers = service.farmers;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACCOUNTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.accountsTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              _buildModuleExportButtons(context, 'Farmer Accounts', locale),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: farmers.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final farmer = farmers[index];
                  final isPending = farmer.status == 'Pending';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPending ? Colors.orange.withValues(alpha: 0.2) : primaryAccent.withValues(alpha: 0.15),
                      foregroundColor: isPending ? Colors.orange : primaryAccent,
                      child: Icon(isPending ? Icons.pending_actions_rounded : Icons.person_rounded),
                    ),
                    title: Text('${farmer.profileName} (@${farmer.username})', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('Status: ${farmer.status} • Barangay: ${farmer.barangay}', style: TextStyle(color: subtextColor)),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        if (isPending)
                          ElevatedButton(
                            onPressed: () => service.setFarmerStatus(farmer.id, 'Active'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                            child: const Text('Approve'),
                          ),
                        OutlinedButton(
                          onPressed: () => _showResetPasswordDialog(context, service, farmer),
                          child: const Text('Reset Pass'),
                        ),
                        IconButton(
                          icon: Icon(farmer.status == 'Deactivated' ? Icons.check_circle_rounded : Icons.block_rounded, color: farmer.status == 'Deactivated' ? Colors.green : Colors.redAccent),
                          onPressed: () => service.setFarmerStatus(farmer.id, farmer.status == 'Deactivated' ? 'Active' : 'Deactivated'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, AccountService service, Farmer farmer) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password for ${farmer.profileName}'),
        content: TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'New Password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (passCtrl.text.isNotEmpty) {
                service.resetFarmerPassword(farmer.id, passCtrl.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully!')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 7: CROP PLANTING REQUIREMENTS (WITH MODULE EXPORT)
  // ==========================================
  Widget _buildCropRequirementsView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final reqs = service.cropRequirements;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AGRONOMY SPECS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.cropReqTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildModuleExportButtons(context, 'Crop Requirements', locale),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCropReqDialog(context, service),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(locale.addCropSpecs, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: reqs.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final c = reqs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber.withValues(alpha: 0.2),
                      foregroundColor: Colors.amber.shade800,
                      child: const Icon(Icons.eco_rounded),
                    ),
                    title: Text('${c.cropName} [${c.cropCategory}]', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('Temp: ${c.minTemp}°C - ${c.maxTemp}°C • Rainfall: ${c.minRainfallMm}-${c.maxRainfallMm} mm\nSuitable Months: ${c.suitableMonths}', style: TextStyle(color: subtextColor)),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                      onPressed: () => service.deleteCropRequirement(c.id),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCropReqDialog(BuildContext context, AccountService service) {
    final nameCtrl = TextEditingController();
    final minTempCtrl = TextEditingController(text: '20.0');
    final maxTempCtrl = TextEditingController(text: '32.0');
    final minRainCtrl = TextEditingController(text: '100.0');
    final maxRainCtrl = TextEditingController(text: '250.0');
    final monthsCtrl = TextEditingController(text: 'June - November');
    String selectedCategory = 'Rice';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Crop Planting Requirement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Crop Name (e.g., Palay, Talong)')),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Rice', 'Prutas', 'Gulay'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => selectedCategory = val ?? 'Rice',
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: minTempCtrl, decoration: const InputDecoration(labelText: 'Min Temp (°C)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: maxTempCtrl, decoration: const InputDecoration(labelText: 'Max Temp (°C)'))),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: minRainCtrl, decoration: const InputDecoration(labelText: 'Min Rain (mm)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: maxRainCtrl, decoration: const InputDecoration(labelText: 'Max Rain (mm)'))),
                ],
              ),
              TextField(controller: monthsCtrl, decoration: const InputDecoration(labelText: 'Suitable Planting Months')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              service.addCropRequirement(
                cropName: nameCtrl.text,
                cropCategory: selectedCategory,
                minTemp: double.tryParse(minTempCtrl.text) ?? 20.0,
                maxTemp: double.tryParse(maxTempCtrl.text) ?? 30.0,
                minRainfallMm: double.tryParse(minRainCtrl.text) ?? 100.0,
                maxRainfallMm: double.tryParse(maxRainCtrl.text) ?? 200.0,
                suitableMonths: monthsCtrl.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 8: MODEL MANAGEMENT (WITH MODULE EXPORT)
  // ==========================================
  Widget _buildModelManagementView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final status = service.modelStatus;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MACHINE LEARNING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.modelTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              _buildModuleExportButtons(context, 'ML Model Status', locale),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yield Prediction ML Model v2.4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                        Text('Trained on historical MAO records', style: TextStyle(color: subtextColor, fontSize: 12)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: status.isTraining ? null : () => service.triggerModelRetraining(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: status.isTraining
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.sync_rounded),
                      label: Text(status.isTraining ? locale.retrainingModel : locale.retrainModel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(height: 30),

                Text('Model Accuracy Metrics:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMetricBadge('MAE (Mean Abs Error)', '${status.mae} MT', const Color(0xFF0056B3), isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricBadge('RMSE (Root Mean Sq)', '${status.rmse} MT', const Color(0xFF4F46E5), isDark)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricBadge('MAPE (Mean Abs %)', '${status.mape}%', const Color(0xFF0284C7), isDark)),
                  ],
                ),
                const SizedBox(height: 20),

                Text('Last Updated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(status.lastUpdated)}', style: TextStyle(color: textColor)),
                const SizedBox(height: 4),
                Text('Training Dataset Size: ${status.trainedRecordsCount} historical entries', style: TextStyle(color: subtextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 9: ADMIN ACCOUNTS
  // ==========================================
  Widget _buildAdminAccountsView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final staff = service.adminStaffList;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MAO STAFF ACCESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.adminStaffTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddStaffDialog(context, service),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.person_add_rounded),
                label: Text(locale.addStaff, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: staff.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final s = staff[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryAccent.withValues(alpha: 0.15),
                      foregroundColor: primaryAccent,
                      child: const Icon(Icons.badge_rounded),
                    ),
                    title: Text('${s.name} (${s.role})', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text('Username: ${s.username} • Email: ${s.email}', style: TextStyle(color: subtextColor)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                      onPressed: () => service.deleteAdminStaff(s.id),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context, AccountService service) {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'Agricultural Technician';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add MAO Staff Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Staff Name')),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role / Position'),
                items: ['Municipal Agriculturist', 'Administrative Staff', 'Agricultural Technician'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => selectedRole = val ?? 'Agricultural Technician',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && userCtrl.text.isNotEmpty) {
                service.addAdminStaff(
                  name: nameCtrl.text,
                  username: userCtrl.text,
                  email: emailCtrl.text.isEmpty ? '${userCtrl.text}@pagsanjan.gov.ph' : emailCtrl.text,
                  role: selectedRole,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MODULE 10: ACTIVITY LOG (WITH MODULE EXPORT)
  // ==========================================
  Widget _buildActivityLogView(
    AccountService service,
    AdminLocale locale,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subtextColor,
    Color cardBorder,
    Color primaryAccent,
  ) {
    final logs = service.activityLogs;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AUDIT TRAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.activityLogTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              _buildModuleExportButtons(context, 'Activity Log Audit', locale),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: logs.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  Color actionColor;
                  switch (log.action) {
                    case 'ADD':
                    case 'UPLOAD':
                      actionColor = const Color(0xFF0284C7);
                      break;
                    case 'EDIT':
                    case 'POST':
                      actionColor = const Color(0xFF0056B3);
                      break;
                    case 'DELETE':
                      actionColor = Colors.redAccent;
                      break;
                    case 'RETRAIN':
                      actionColor = const Color(0xFF4F46E5);
                      break;
                    case 'SWITCH':
                      actionColor = Colors.orange;
                      break;
                    default:
                      actionColor = Colors.grey;
                  }

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: actionColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(log.action, style: TextStyle(fontWeight: FontWeight.bold, color: actionColor, fontSize: 11)),
                    ),
                    title: Text(log.details, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                    subtitle: Text('By: ${log.user} • Module: ${log.module}', style: TextStyle(color: subtextColor)),
                    trailing: Text(DateFormat('MMM dd, yyyy HH:mm').format(log.timestamp), style: TextStyle(fontSize: 11, color: subtextColor)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DIALOG FOR ANNOUNCEMENT POSTS
  void _showCreatePostDialog(BuildContext context, AccountService service, AdminLocale locale) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.isTagalog ? 'Gumawa ng Anunsyo' : 'Create Office Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: InputDecoration(labelText: locale.isTagalog ? 'Pamagat' : 'Title')),
              const SizedBox(height: 8),
              TextField(controller: contentCtrl, decoration: InputDecoration(labelText: locale.isTagalog ? 'Lalamanin' : 'Content'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(locale.isTagalog ? 'Kanselahin' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                service.addPost(titleCtrl.text, contentCtrl.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(locale.isTagalog ? 'Naipost na ang anunsyo!' : 'Announcement posted successfully!')));
              }
            },
            child: Text(locale.isTagalog ? 'I-post' : 'Post'),
          ),
        ],
      ),
    );
  }
}
