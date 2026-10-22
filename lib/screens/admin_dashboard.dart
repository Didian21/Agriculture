import 'dart:convert';
import 'dart:io';
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
  String get navFarmers => isTagalog ? 'Mga Magsasaka at Sakahan' : 'Farmer & Farm Records';
  String get navHistorical => isTagalog ? 'Nakaraang Datos' : 'Historical Data';
  String get navMap => isTagalog ? 'Mapang Interaktibo' : 'Interactive Map';
  String get navAccounts => isTagalog ? 'Mga Akawnt ng Farmer' : 'Farmer Accounts';
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
  String get farmersPerBarangay => isTagalog ? 'Bilang ng Magsasaka Bawat Barangay' : 'Farmers per Barangay';
  String get areaPerCrop => isTagalog ? 'Lupaing Sakahan Bawat Uri ng Tanim' : 'Farm Area per Crop Type';
  String get historicalTrends => isTagalog ? 'Nakaraang Trend sa Ani at Presyo (MAO)' : 'Historical Production & Price Trends (MAO)';

  // Weather
  String get weatherTitle => isTagalog ? 'Ulat ng Panahon sa Agrikultura' : 'Pagsanjan Agricultural Weather';
  String get liveUpdated => isTagalog ? 'BAGO AT LIVE' : 'LIVE UPDATED';
  String get weatherForecast => isTagalog ? '5-Araw na Ulat ng Panahon sa Sakahan' : '5-Day Agricultural Weather Forecast';
  String get weatherAdvisory => isTagalog ? '🌾 Payo: Angkop ang panahon para sa pagpapataba' : '🌾 Advisory: Favorable for fertilizer application';

  // Farmer & Farm Records
  String get farmerDirTitle => isTagalog ? 'Direktoryo ng mga Magsasaka at Sakahan' : 'Farmer & Farm Records Management';
  String get addFarmer => isTagalog ? 'Magdagdag ng Magsasaka' : 'Add Farmer';
  String get addFarmRecord => isTagalog ? 'Magdagdag ng Sakahan' : 'Add Farm';
  String get searchFarmerPlaceholder => isTagalog ? 'Magsaliksik ng pangalan, username, o samahan...' : 'Search farmer name, username, or association...';

  // Historical Data
  String get historicalTitle => isTagalog ? 'Mga Nakaraang Rekord ng MAO' : 'Historical Production & Price Data';
  String get uploadMaoRecord => isTagalog ? 'Mag-upload ng Rekord' : 'Upload MAO Record';

  // Interactive Map
  String get mapTitle => isTagalog ? 'Interaktibong Mapa ng mga Sakahan' : 'Interactive Farm Map (Pagsanjan)';
  String get registeredPins => isTagalog ? 'Mga Pin ng Rehistradong Sakahan' : 'Registered Farm Pins';

  // Farmer Accounts
  String get accountsTitle => isTagalog ? 'Pamamahala ng mga Akawnt ng Farmer' : 'Farmer Accounts Management';

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
  int _selectedIndex = 0; // 0..6 for the 7 main modules
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filters for Dashboard Summary
  String _selectedCropFilter = 'All';
  String _selectedBarangayFilter = 'All';
  String _selectedTimePeriodFilter = 'All';

  final ScrollController _kpiScrollController = ScrollController();
  final ScrollController _sidebarScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _kpiScrollController.dispose();
    _sidebarScrollController.dispose();
    super.dispose();
  }

  String _generateValidPdfContent(String title, String bodyText) {
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final safeTitle = title.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');

    final lines = bodyText.replaceAll('\r', '').split('\n').take(30).toList();
    final bodyLinesBuffer = StringBuffer();
    for (final l in lines) {
      if (l.trim().isEmpty) continue;
      final safeLine = l.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
      bodyLinesBuffer.writeln('($safeLine) Tj T*');
    }

    final streamText = '''BT
/F1 14 Tf
16 TL
50 740 Td
($safeTitle) Tj T*
/F1 9 Tf
12 TL
(Generated on: $now | Pagsanjan MAO System) Tj T*
0 -10 Td
${bodyLinesBuffer.toString().trim()}
ET''';

    final streamBytesLength = streamText.length;

    final header = '%PDF-1.4\n';

    final obj1 = '''1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
''';

    final obj2 = '''2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
''';

    final obj3 = '''3 0 obj
<< /Type /Page /Parent 2 0 R /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /MediaBox [0 0 612 792] /Contents 4 0 R >>
endobj
''';

    final obj4Header = '4 0 obj\n<< /Length $streamBytesLength >>\nstream\n';
    final obj4Footer = '\nendstream\nendobj\n';

    final offset1 = header.length;
    final offset2 = offset1 + obj1.length;
    final offset3 = offset2 + obj2.length;
    final offset4 = offset3 + obj3.length;
    final offsetXref = offset4 + obj4Header.length + streamBytesLength + obj4Footer.length;

    String formatOffset(int offset) => offset.toString().padLeft(10, '0');

    final xref = '''xref
0 5
0000000000 65535 f 
${formatOffset(offset1)} 00000 n 
${formatOffset(offset2)} 00000 n 
${formatOffset(offset3)} 00000 n 
${formatOffset(offset4)} 00000 n 
trailer
<< /Size 5 /Root 1 0 R >>
startxref
$offsetXref
%%EOF''';

    return '$header$obj1$obj2$obj3$obj4Header$streamText$obj4Footer$xref';
  }

  String _generateExportContent(String moduleName, String format, AccountService service) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final isCsv = format.toLowerCase().contains('excel') || format.toLowerCase().contains('csv');
    final mod = moduleName.toLowerCase();

    if (isCsv) {
      final sb = StringBuffer();
      sb.writeln('PAGSANJAN MUNICIPAL AGRICULTURE OFFICE (MAO)');
      sb.writeln('OFFICIAL EXPORT REPORT: ${moduleName.toUpperCase()}');
      sb.writeln('GENERATED ON: $dateStr');
      sb.writeln('OPERATOR: ${service.activeUserName}');
      sb.writeln('');

      if (mod.contains('farmer') && mod.contains('farm')) {
        sb.writeln('Farmer ID,Full Personal Name,Username,Barangay,Contact Details,Association / Org,Status,Farm Sitio,Land Area (ha),Tenure Status,Crop Type');
        for (final f in service.farmers) {
          final farmerFarms = service.farms.where((farm) => farm.farmerId == f.id || farm.farmerName == f.profileName).toList();
          if (farmerFarms.isEmpty) {
            sb.writeln('${f.id},"${f.profileName}",${f.username},${f.barangay},${f.contactNumber},"${f.organization}",${f.status},N/A,0.0,N/A,N/A');
          } else {
            for (final farm in farmerFarms) {
              sb.writeln('${f.id},"${f.profileName}",${f.username},${f.barangay},${f.contactNumber},"${f.organization}",${f.status},"${farm.locationName}",${farm.landAreaHectares},${farm.tenureStatus},${farm.cropType}');
            }
          }
        }
      } else if (mod.contains('account')) {
        if (mod.contains('admin')) {
          sb.writeln('Staff ID,Staff Name,Username,Email Address,Role / Position,Status');
          for (final s in service.adminStaffList) {
            sb.writeln('${s.id},"${s.name}",${s.username},${s.email},"${s.role}",${s.status}');
          }
        } else {
          sb.writeln('Farmer ID,Full Name,Username,Barangay,Contact Details,Organization,Account Status');
          for (final f in service.farmers) {
            sb.writeln('${f.id},"${f.profileName}",${f.username},${f.barangay},${f.contactNumber},"${f.organization}",${f.status}');
          }
        }
      } else if (mod.contains('historical')) {
        sb.writeln('Record ID,Crop,Year,Month,Production (MT),Price per Kg (PHP),Uploaded By');
        for (final h in service.historicalRecords) {
          sb.writeln('${h.id},${h.crop},${h.year},${h.month},${h.productionMT},${h.pricePerKg},"${h.uploadedBy}"');
        }
      } else if (mod.contains('map')) {
        sb.writeln('Farm ID,Farmer Name,Sitio Location,Barangay,Latitude,Longitude,Land Area (ha),Tenure,Crop Type');
        for (final farm in service.farms) {
          sb.writeln('${farm.id},"${farm.farmerName}","${farm.locationName}",${farm.barangay},${farm.latitude},${farm.longitude},${farm.landAreaHectares},${farm.tenureStatus},${farm.cropType}');
        }
      } else if (mod.contains('activity') || mod.contains('log')) {
        sb.writeln('Log ID,Timestamp,Operator User,Module,Action,Details');
        for (final l in service.activityLogs) {
          sb.writeln('${l.id},"${DateFormat('yyyy-MM-dd HH:mm').format(l.timestamp)}",${l.user},${l.module},${l.action},"${l.details}"');
        }
      } else {
        sb.writeln('Metric Title,Value,Details');
        sb.writeln('Registered Farmers,${service.farmers.length},Active Agricultural Directory');
        final totalArea = service.farms.fold(0.0, (sum, item) => sum + item.landAreaHectares);
        sb.writeln('Total Farm Area (ha),${totalArea.toStringAsFixed(1)},Pagsanjan Registered Farmlands');
        sb.writeln('Historical Records,${service.historicalRecords.length},MAO Production Data');
        sb.writeln('Audit Log Items,${service.activityLogs.length},Logged System Operations');
      }
      return sb.toString();
    } else {
      final textSb = StringBuffer();
      if (mod.contains('farmer') && mod.contains('farm')) {
        for (final f in service.farmers) {
          final farmerFarms = service.farms.where((farm) => farm.farmerId == f.id || farm.farmerName == f.profileName).toList();
          textSb.writeln('FARMER: ${f.profileName} (@${f.username}) - Brgy. ${f.barangay}');
          textSb.writeln('Contact: ${f.contactNumber} | Org: ${f.organization} | Status: ${f.status}');
          for (final farm in farmerFarms) {
            textSb.writeln('  -> Farm: ${farm.cropType} (${farm.landAreaHectares} ha, ${farm.tenureStatus}) - ${farm.locationName}');
          }
          textSb.writeln('');
        }
      } else if (mod.contains('historical')) {
        for (final h in service.historicalRecords) {
          textSb.writeln('RECORD ${h.id}: ${h.crop} (${h.month} ${h.year}) - ${h.productionMT} MT @ PHP ${h.pricePerKg}/kg [By: ${h.uploadedBy}]');
        }
      } else if (mod.contains('map')) {
        for (final farm in service.farms) {
          textSb.writeln('PIN ${farm.id}: ${farm.farmerName} - ${farm.cropType} (${farm.landAreaHectares} ha) @ ${farm.locationName}, ${farm.barangay}');
        }
      } else if (mod.contains('activity') || mod.contains('log')) {
        for (final l in service.activityLogs) {
          textSb.writeln('[${DateFormat('MM-dd HH:mm').format(l.timestamp)}] ${l.user} (${l.action} in ${l.module}): ${l.details}');
        }
      } else {
        textSb.writeln('REGISTERED FARMERS COUNT: ${service.farmers.length}');
        textSb.writeln('TOTAL FARM AREA: ${service.farms.fold(0.0, (s, i) => s + i.landAreaHectares).toStringAsFixed(1)} hectares');
        textSb.writeln('HISTORICAL RECORDS: ${service.historicalRecords.length} entries');
      }
      return _generateValidPdfContent('PAGSANJAN MAO REPORT: ${moduleName.toUpperCase()}', textSb.toString());
    }
  }

  Future<String?> _saveContentToUserDirectory(String fileName, String content, String selectedFolder) async {
    try {
      String baseDir;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
        baseDir = '$userProfile\\$selectedFolder';
      } else {
        baseDir = Directory.systemTemp.path;
      }
      final dir = Directory(baseDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final filePath = '$baseDir\\$fileName';
      final file = File(filePath);
      await file.writeAsString(content);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  void _triggerExport(BuildContext context, String fullType, bool isTagalog) {
    final service = Provider.of<AccountService>(context, listen: false);
    final parts = fullType.split('(');
    final moduleName = parts[0].trim();
    final format = parts.length > 1 ? parts[1].replaceAll(')', '').trim() : 'CSV';
    final isPdf = format.toLowerCase().contains('pdf');
    final content = _generateExportContent(moduleName, format, service);
    final ext = isPdf ? 'pdf' : 'csv';
    final fileName = 'PAGSANJAN_MAO_${moduleName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    String chosenFolder = 'Downloads';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isPdf ? Icons.picture_as_pdf_rounded : Icons.table_chart_rounded, color: isPdf ? Colors.redAccent : const Color(0xFF0284C7)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTagalog ? 'Export & Save File ($ext)' : 'Export & Save File ($ext)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTagalog
                      ? 'Pumili kung saang folder sa iyong computer ilalagay ang idodownload na .$ext file:'
                      : 'Choose which directory in your device to save the exported .$ext file:',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: chosenFolder,
                  decoration: InputDecoration(
                    labelText: isTagalog ? 'Pumili ng Folder/Directory' : 'Select Destination Directory',
                    prefixIcon: const Icon(Icons.folder_special_rounded, color: Color(0xFF0056B3)),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Downloads', child: Text('Downloads Folder (C:\\Users\\...\\Downloads)')),
                    DropdownMenuItem(value: 'Documents', child: Text('Documents Folder (C:\\Users\\...\\Documents)')),
                    DropdownMenuItem(value: 'Desktop', child: Text('Desktop Folder (C:\\Users\\...\\Desktop)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => chosenFolder = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text('File Name: $fileName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isTagalog ? 'Kanselahin' : 'Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
              onPressed: () async {
                final savedPath = await _saveContentToUserDirectory(fileName, content, chosenFolder);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        savedPath != null
                            ? (isTagalog
                                ? 'Matagumpay na nai-save ang $fileName sa: $savedPath'
                                : 'Successfully saved $fileName to: $savedPath')
                            : (isTagalog
                                ? 'Nai-save ang file na $fileName!'
                                : 'File $fileName saved!'),
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: Text(isTagalog ? 'I-download sa Selected Folder' : 'Download to Selected Folder'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickFileWithSystemExplorer() async {
    try {
      if (Platform.isWindows) {
        const psScript = r'''
Add-Type -AssemblyName System.Windows.Forms
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Filter = "Data Files (*.csv;*.txt;*.pdf)|*.csv;*.txt;*.pdf|All Files (*.*)|*.*"
$dlg.Title = "Pagsanjan MAO - Select File to Import"
$dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    Write-Host $dlg.FileName
}
''';
        final utf16Units = psScript.codeUnits;
        final utf16Bytes = <int>[];
        for (final unit in utf16Units) {
          utf16Bytes.add(unit & 0xFF);
          utf16Bytes.add((unit >> 8) & 0xFF);
        }
        final b64 = base64.encode(utf16Bytes);

        final result = await Process.run('powershell', ['-NoProfile', '-EncodedCommand', b64]);
        if (result.exitCode == 0) {
          final path = (result.stdout as String).trim();
          if (path.isNotEmpty && await File(path).exists()) {
            return path;
          }
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
    return null;
  }

  void _showImportDialog(BuildContext context, String moduleName, AccountService service, AdminLocale locale) {
    final isTagalog = locale.isTagalog;
    String selectedSourceDir = 'Downloads';
    final fileNameCtrl = TextEditingController(text: '');
    final csvCtrl = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.upload_file_rounded, color: Color(0xFF16A34A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTagalog ? 'Mag-import ng File - $moduleName' : 'Import File - $moduleName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTagalog
                      ? 'I-click ang button sa ibaba upang buksan ang File Explorer ng iyong computer at pumili ng file:'
                      : 'Click the button below to open File Explorer and choose a file from your device:',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 14),

                // NATIVE FILE EXPLORER BROWSE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      final pickedPath = await _pickFileWithSystemExplorer();
                      if (pickedPath != null && pickedPath.isNotEmpty) {
                        final file = File(pickedPath);
                        if (await file.exists()) {
                          final content = await file.readAsString();
                          setDialogState(() {
                            fileNameCtrl.text = pickedPath;
                            csvCtrl.text = content;
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTagalog
                                      ? 'Matagumpay na na-load ang file: $pickedPath'
                                      : 'Successfully loaded file: $pickedPath',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.folder_open_rounded, size: 20),
                    label: Text(
                      isTagalog ? '📁 Pumili ng File sa File Explorer (Browse)' : '📁 Choose File in File Explorer (Browse)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        isTagalog ? 'o manwal na pumili sa folder' : 'or manually select from directory',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedSourceDir,
                        decoration: InputDecoration(
                          labelText: isTagalog ? 'Folder' : 'Folder',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Downloads', child: Text('Downloads')),
                          DropdownMenuItem(value: 'Documents', child: Text('Documents')),
                          DropdownMenuItem(value: 'Desktop', child: Text('Desktop')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedSourceDir = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: fileNameCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: isTagalog ? 'Pangalan ng File / Path' : 'File Name / Path',
                          hintText: 'mga_magsasaka.csv',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final folder = selectedSourceDir;
                      final fname = fileNameCtrl.text.trim();
                      if (fname.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              isTagalog
                                  ? 'Mangyaring pumili ng file sa File Explorer o maglagay ng pangalan ng file.'
                                  : 'Please choose a file via File Explorer or enter a file name.',
                            ),
                            backgroundColor: Colors.orange.shade800,
                          ),
                        );
                        return;
                      }

                      try {
                        String fullPath = fname;
                        if (!fname.contains('\\') && !fname.contains('/')) {
                          String userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
                          fullPath = '$userProfile\\$folder\\$fname';
                        }
                        final file = File(fullPath);
                        if (await file.exists()) {
                          final textContent = await file.readAsString();
                          setDialogState(() {
                            fileNameCtrl.text = fullPath;
                            csvCtrl.text = textContent;
                          });
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTagalog
                                      ? 'Matagumpay na nabasa ang file mula sa: $fullPath'
                                      : 'Successfully read file from: $fullPath',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTagalog
                                      ? 'Hindi nahanap ang file sa $fullPath.'
                                      : 'File not found at $fullPath.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTagalog
                                    ? 'Nagkaroon ng error sa pagbasa ng file: $e'
                                    : 'Error reading file: $e',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.file_present_rounded, size: 16),
                    label: Text(isTagalog ? 'Kargahin ang File mula sa Path' : 'Load File from Specified Path'),
                  ),
                ),
                if (fileNameCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileNameCtrl.text,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isTagalog ? 'Kanselahin' : 'Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () {
                final rawText = csvCtrl.text.trim();
                if (rawText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isTagalog
                            ? 'Walang kargang file! Mangyaring mag-upload muna ng file sa File Explorer.'
                            : 'No file loaded! Please choose a file via File Explorer first.',
                      ),
                      backgroundColor: Colors.orange.shade800,
                    ),
                  );
                  return;
                }

                final lines = rawText.split('\n');
                int importedCount = 0;

                for (final line in lines) {
                  final parts = line.split(',');
                  if (parts.length >= 2) {
                    final name = parts[0].trim();
                    final user = parts[1].trim();
                    final barangay = parts.length > 2 && parts[2].trim().isNotEmpty ? parts[2].trim() : 'Biñan';
                    final contact = parts.length > 3 && parts[3].trim().isNotEmpty ? parts[3].trim() : '09170000000';
                    final org = parts.length > 4 && parts[4].trim().isNotEmpty ? parts[4].trim() : 'Pagsanjan Farmers Assoc';
                    final crop = parts.length > 5 && parts[5].trim().isNotEmpty ? parts[5].trim() : 'Rice';
                    final land = parts.length > 6 ? (double.tryParse(parts[6].trim()) ?? 2.0) : 2.0;

                    if (name.isNotEmpty && user.isNotEmpty) {
                      final farmerId = 'F${DateTime.now().millisecondsSinceEpoch}_$importedCount';
                      service.addFarmer(
                        username: user,
                        password: 'password123',
                        profileName: name,
                        barangay: barangay,
                        contactNumber: contact,
                        organization: org,
                      );
                      service.addFarmRecord(
                        farmerId: farmerId,
                        farmerName: name,
                        locationName: 'Sitio $barangay',
                        latitude: 14.2717,
                        longitude: 121.4553,
                        landAreaHectares: land,
                        tenureStatus: 'Owner',
                        cropType: crop,
                        barangay: barangay,
                      );
                      importedCount++;
                    }
                  }
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isTagalog
                          ? 'Matagumpay na na-import ang $importedCount mga bagong magsasaka at sakahan mula sa iyong na-upload na file!'
                          : 'Successfully imported $importedCount new farmers and farms from your uploaded file!',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: Text(isTagalog ? 'I-process at I-import' : 'Process & Import'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportImportButtons(BuildContext context, String moduleName, AdminLocale locale, AccountService service, {bool showImport = true}) {
    final isTagalog = locale.isTagalog;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // COMBINED EXPORT BUTTON (PDF & Excel/CSV)
        PopupMenuButton<String>(
          tooltip: isTagalog ? 'Mga Pagpipilian sa Pag-export' : 'Export Options',
          offset: const Offset(0, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            _triggerExport(context, '$moduleName ($val)', isTagalog);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'PDF',
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Text(locale.exportPdf, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'Excel/CSV',
              child: Row(
                children: [
                  const Icon(Icons.table_chart_rounded, color: Color(0xFF0284C7), size: 18),
                  const SizedBox(width: 8),
                  Text(locale.exportExcel, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF0056B3)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download_rounded, size: 16, color: Color(0xFF0056B3)),
                const SizedBox(width: 6),
                Text(isTagalog ? 'Export ▾' : 'Export ▾', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0056B3))),
              ],
            ),
          ),
        ),

        // SINGLE DIRECT IMPORT BUTTON (Opens File Explorer dialog directly)
        if (showImport)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () {
              _showImportDialog(context, moduleName, service, locale);
            },
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: Text(
              isTagalog ? 'I-import ang File' : 'Import File',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
      ],
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
    final sidebarBg = isDark ? const Color(0xFF081427) : const Color(0xFFE3F2FD);
    final cardBg = isDark ? const Color(0xFF121E31) : Colors.white;
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBorder = isDark ? const Color(0xFF1E2E4A) : const Color(0xFFD0E1F9);
    final primaryAccent = isDark ? const Color(0xFF38BDF8) : const Color(0xFF0056B3);
    final secondaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);

    final sidebarContent = Container(
      width: 275,
      color: sidebarBg,
      child: Scrollbar(
        controller: _sidebarScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _sidebarScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Branding Widget
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

              // ACTIVE STAFF OPERATOR CARD
              InkWell(
                onTap: () => _showSwitchStaffDialog(context, service, locale),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white24 : const Color(0xFF90CAF9)),
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
                              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              service.activeStaff.role,
                              style: TextStyle(color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0056B3), fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.swap_vert_rounded, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0056B3), size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: isDark ? Colors.white12 : const Color(0xFF90CAF9), height: 1),
              ),
              const SizedBox(height: 8),

              // Nav Items List (0 to 6 unified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    _buildNavItem(icon: Icons.dashboard_rounded, label: locale.navDashboard, index: 0, isDark: isDark),
                    _buildNavItem(icon: Icons.badge_rounded, label: locale.navFarmers, index: 1, isDark: isDark),
                    _buildNavItem(icon: Icons.history_edu_rounded, label: locale.navHistorical, index: 2, isDark: isDark),
                    _buildNavItem(icon: Icons.map_rounded, label: locale.navMap, index: 3, isDark: isDark),
                    _buildNavItem(icon: Icons.manage_accounts_rounded, label: locale.navAccounts, index: 4, isDark: isDark),
                    _buildNavItem(icon: Icons.supervisor_account_rounded, label: locale.navAdminStaff, index: 5, isDark: isDark),
                    _buildNavItem(icon: Icons.receipt_long_rounded, label: locale.navActivityLog, index: 6, isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
        mainContentArea = _buildHistoricalDataView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 3:
        mainContentArea = _buildInteractiveMapView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 4:
        mainContentArea = _buildFarmerAccountsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 5:
        mainContentArea = _buildAdminAccountsView(service, locale, isDark, cardBg, textColor, subtextColor, cardBorder, primaryAccent);
        break;
      case 6:
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

          // LANGUAGE TOGGLE BUTTON
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
        drawer: Drawer(
          backgroundColor: sidebarBg,
          child: sidebarContent,
        ),
        body: fullBody,
      );
    }
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required bool isDark}) {
    final isSelected = _selectedIndex == index;
    final activeBg = isDark ? const Color(0xFF2563EB).withValues(alpha: 0.25) : const Color(0xFF0056B3).withValues(alpha: 0.15);
    final activeText = isDark ? const Color(0xFF60A5FA) : const Color(0xFF0056B3);
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF0F172A);
    final inactiveIcon = isDark ? Colors.white60 : const Color(0xFF0056B3);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: activeText.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? activeText : inactiveIcon, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeText : inactiveText,
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
  // MODULE 1: DASHBOARD SUMMARY
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

    final filteredFarms = farms.where((f) {
      final matchesBarangay = _selectedBarangayFilter == 'All' || f.barangay == _selectedBarangayFilter;
      final matchesCrop = _selectedCropFilter == 'All' || f.cropType == _selectedCropFilter;
      return matchesBarangay && matchesCrop;
    }).toList();

    final filteredFarmers = farmers.where((f) {
      final matchesBarangay = _selectedBarangayFilter == 'All' || f.barangay == _selectedBarangayFilter;
      if (!matchesBarangay) return false;
      if (_selectedCropFilter == 'All') return true;
      final farmerFarms = farms.where((farm) => farm.farmerId == f.id || farm.farmerName == f.profileName);
      return farmerFarms.any((farm) => farm.cropType == _selectedCropFilter);
    }).toList();

    final filteredHistorical = historical.where((h) {
      final matchesCrop = _selectedCropFilter == 'All' || h.crop == _selectedCropFilter;
      if (!matchesCrop) return false;
      if (_selectedTimePeriodFilter == 'All') return true;
      if (_selectedTimePeriodFilter == '2026') return h.year == 2026;
      if (_selectedTimePeriodFilter == '2025') return h.year == 2025;
      final m = h.month.toLowerCase();
      if (_selectedTimePeriodFilter == 'Wet Season') {
        return m.contains('may') || m.contains('jun') || m.contains('jul') || m.contains('aug') || m.contains('sep') || m.contains('oct');
      }
      if (_selectedTimePeriodFilter == 'Dry Season') {
        return m.contains('nov') || m.contains('dec') || m.contains('jan') || m.contains('feb') || m.contains('mar') || m.contains('apr');
      }
      return true;
    }).toList();

    final totalFarmersCount = filteredFarmers.length;
    final totalFarmArea = filteredFarms.fold(0.0, (sum, item) => sum + item.landAreaHectares);

    final Map<String, int> farmersPerBarangay = {};
    for (final f in filteredFarmers) {
      farmersPerBarangay[f.barangay] = (farmersPerBarangay[f.barangay] ?? 0) + 1;
    }

    final Map<String, double> areaPerCrop = {};
    for (final farm in filteredFarms) {
      areaPerCrop[farm.cropType] = (areaPerCrop[farm.cropType] ?? 0.0) + farm.landAreaHectares;
    }

    return SingleChildScrollView(
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
                  Text(locale.execSummary, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent, letterSpacing: 1.1)),
                  const SizedBox(height: 2),
                  Text(locale.agriOverview, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              _buildExportImportButtons(context, 'Full Executive Summary', locale, service, showImport: false),
            ],
          ),
          const SizedBox(height: 18),

          // Filter Controls Card
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
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedBarangayFilter,
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
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCropFilter,
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
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTimePeriodFilter,
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

          // KPI Cards Summary Row with 2 Wider KPI Cards (Registered Farmers & Total Farm Area) & Scrollbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121E31) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF1E2E4A) : const Color(0xFF90CAF9)),
            ),
            child: Scrollbar(
              controller: _kpiScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _kpiScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 380,
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
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 380,
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
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Weather Card
          _buildWeatherCard(locale, isDark, cardBg, textColor, primaryAccent),
          const SizedBox(height: 20),

          // Data Breakdown Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                if (filteredHistorical.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('No historical records match the selected filters.', style: TextStyle(color: subtextColor, fontSize: 13)),
                  )
                else
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
                      rows: filteredHistorical.map((h) => DataRow(
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
  // MODULE 2: UNIFIED FARMER & FARM RECORDS
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
                  Text('DIRECTORY & LANDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.farmerDirTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildExportImportButtons(context, 'Farmer and Farm Records', locale, service),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

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

          Expanded(
            child: ListView.builder(
              itemCount: farmers.length,
              itemBuilder: (context, index) {
                final farmer = farmers[index];
                final farmerFarms = service.farms.where((f) => f.farmerId == farmer.id || f.farmerName == farmer.profileName).toList();

                return Card(
                  color: cardBg,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cardBorder),
                  ),
                  elevation: isDark ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Farmer Personal Details Header
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryAccent.withValues(alpha: 0.15),
                              foregroundColor: primaryAccent,
                              radius: 22,
                              child: Text(farmer.profileName.isNotEmpty ? farmer.profileName[0] : 'F', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(farmer.profileName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: farmer.status == 'Active' ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(farmer.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: farmer.status == 'Active' ? Colors.green : Colors.orange)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Username: @${farmer.username} • Barangay: ${farmer.barangay} • Contact: ${farmer.contactNumber}', style: TextStyle(fontSize: 12, color: subtextColor)),
                                  Text('Organization: ${farmer.organization}', style: TextStyle(fontSize: 12, color: subtextColor)),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                                  tooltip: 'Edit Farmer',
                                  onPressed: () => _showEditFarmerDialog(context, service, farmer),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF0284C7), size: 20),
                                  tooltip: 'Add Farm Record for Farmer',
                                  onPressed: () => _showAddFarmForFarmerDialog(context, service, farmer),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                  tooltip: 'Delete Farmer',
                                  onPressed: () => service.deleteFarmer(farmer.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Associated Farm Records Section (Directly Inside Farmer Card)
                        Row(
                          children: [
                            Icon(Icons.landscape_rounded, size: 16, color: primaryAccent),
                            const SizedBox(width: 6),
                            Text(
                              locale.isTagalog ? 'Mga Rekord ng Sakahan (${farmerFarms.length})' : 'Associated Farm Records (${farmerFarms.length})',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (farmerFarms.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Text(
                                  locale.isTagalog ? 'Walang nakatalagang sakahan.' : 'No associated farm records yet.',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: subtextColor),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _showAddFarmForFarmerDialog(context, service, farmer),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: Text(locale.isTagalog ? 'Magdagdag ng Sakahan' : 'Add Farm', style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          )
                        else
                          ...farmerFarms.map((farm) => Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0A111E) : Colors.blue.shade50.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? const Color(0xFF1E2E4A) : Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.eco_rounded, color: Color(0xFF16A34A), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Crop: ${farm.cropType}',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('${farm.landAreaHectares} ha', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(farm.tenureStatus, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Location: ${farm.locationName}, Barangay ${farm.barangay} • GPS: [${farm.latitude.toStringAsFixed(4)}, ${farm.longitude.toStringAsFixed(4)}]',
                                        style: TextStyle(fontSize: 11, color: subtextColor),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  tooltip: 'Delete Farm Record',
                                  onPressed: () => service.deleteFarmRecord(farm.id),
                                ),
                              ],
                            ),
                          )),
                      ],
                    ),
                  ),
                );
              },
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
    final locationCtrl = TextEditingController();
    final landAreaCtrl = TextEditingController(text: '2.5');
    String selectedBrgy = 'Biñan';
    String selectedCrop = 'Rice';
    String selectedTenure = 'Owner';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: Color(0xFF0056B3)),
            SizedBox(width: 8),
            Text('Add New Farmer & Farm Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FARMER ACCOUNT INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
              const SizedBox(height: 8),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Personal Name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedBrgy,
                decoration: const InputDecoration(labelText: 'Barangay', border: OutlineInputBorder()),
                items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => selectedBrgy = val ?? 'Biñan',
              ),
              const SizedBox(height: 10),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Details', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: orgCtrl, decoration: const InputDecoration(labelText: 'Association / Org Membership', border: OutlineInputBorder())),

              const Divider(height: 24),
              const Text('FARM INFORMATION (AUTO-SYNCS TO RECORDS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCrop,
                decoration: const InputDecoration(labelText: 'Primary Crop Type', border: OutlineInputBorder()),
                items: ['Rice', 'Prutas', 'Gulay', 'Corn', 'Coconut'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => selectedCrop = val ?? 'Rice',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: landAreaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Land Area (ha)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedTenure,
                      decoration: const InputDecoration(labelText: 'Tenure Status', border: OutlineInputBorder()),
                      items: ['Owner', 'Tenant', 'Lease', 'CLT'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => selectedTenure = val ?? 'Owner',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Farm Sitio / Location Name', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && userCtrl.text.isNotEmpty) {
                final farmerId = 'F${DateTime.now().millisecondsSinceEpoch}';
                service.addFarmer(
                  username: userCtrl.text,
                  password: passCtrl.text.isEmpty ? 'password123' : passCtrl.text,
                  profileName: nameCtrl.text,
                  barangay: selectedBrgy,
                  contactNumber: contactCtrl.text.isEmpty ? 'N/A' : contactCtrl.text,
                  organization: orgCtrl.text.isEmpty ? 'Independent' : orgCtrl.text,
                );

                // Add associated Farm Record so it syncs automatically to Farmer & Farm Records!
                service.addFarmRecord(
                  farmerId: farmerId,
                  farmerName: nameCtrl.text,
                  locationName: locationCtrl.text.isEmpty ? 'Sitio $selectedBrgy' : locationCtrl.text,
                  latitude: 14.2717,
                  longitude: 121.4553,
                  landAreaHectares: double.tryParse(landAreaCtrl.text) ?? 2.0,
                  tenureStatus: selectedTenure,
                  cropType: selectedCrop,
                  barangay: selectedBrgy,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Matagumpay na naidagdag ang magsasaka at ang kaniyang sakahan!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('Save Farmer & Farm'),
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

  void _showAddFarmForFarmerDialog(BuildContext context, AccountService service, Farmer farmer) {
    final locationCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final latCtrl = TextEditingController(text: '14.2717');
    final lonCtrl = TextEditingController(text: '121.4553');
    String selectedTenure = 'Owner';
    String selectedCrop = 'Rice';
    String selectedBrgy = farmer.barangay;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Farm Record for ${farmer.profileName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: 'Farm Location / Sitio')),
              DropdownButtonFormField<String>(
                value: selectedBrgy,
                decoration: const InputDecoration(labelText: 'Barangay'),
                items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (val) => selectedBrgy = val ?? farmer.barangay,
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
  // MODULE 3: HISTORICAL DATA
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
                  _buildExportImportButtons(context, 'Historical Data', locale, service),
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

          // PREDICTED PRICE & MARKET TRENDS CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132338) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBAE6FD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Color(0xFF0284C7), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      locale.isTagalog ? '💡 Prediksyon ng Presyo at Market Trends (Price Forecasting)' : '💡 Price Prediction & Market Trend Analytics',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildPredictionChip('Rice', service, isDark, textColor, subtextColor),
                    _buildPredictionChip('Gulay', service, isDark, textColor, subtextColor),
                    _buildPredictionChip('Prutas', service, isDark, textColor, subtextColor),
                  ],
                ),
              ],
            ),
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
  // MODULE 4: INTERACTIVE MAP
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
    final farms = service.farms.where((farm) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
                           farm.farmerName.toLowerCase().contains(query) ||
                           farm.locationName.toLowerCase().contains(query) ||
                           farm.cropType.toLowerCase().contains(query);
      final matchesBarangay = _selectedBarangayFilter == 'All' || farm.barangay == _selectedBarangayFilter;
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
                  Text('GIS & WEATHER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.mapTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              _buildExportImportButtons(context, 'Farms Map List', locale, service),
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
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(color: textColor, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: locale.isTagalog ? 'Maghanap ng sakahan...' : 'Search farm or farmer...',
                              hintStyle: TextStyle(color: subtextColor, fontSize: 11),
                              prefixIcon: Icon(Icons.search_rounded, color: subtextColor, size: 18),
                              isDense: true,
                              filled: true,
                              fillColor: cardBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cardBorder)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBarangayFilter,
                            dropdownColor: cardBg,
                            style: TextStyle(color: textColor, fontSize: 12),
                            decoration: InputDecoration(
                              labelText: locale.isTagalog ? 'Barangay' : 'Barangay',
                              labelStyle: TextStyle(color: subtextColor, fontSize: 11),
                              isDense: true,
                              filled: true,
                              fillColor: cardBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cardBorder)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: ['All', ...AccountService.pagsanjanBarangays].map((b) => DropdownMenuItem(value: b, child: Text(b, style: TextStyle(fontSize: 12)))).toList(),
                            onChanged: (val) => setState(() => _selectedBarangayFilter = val ?? 'All'),
                          ),
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
  // MODULE 5: FARMER ACCOUNTS
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
    final farmers = service.farmers.where((f) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = query.isEmpty ||
                           f.profileName.toLowerCase().contains(query) ||
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
                  Text('ACCOUNTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 2),
                  Text(locale.accountsTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildExportImportButtons(context, 'Farmer Accounts', locale, service, showImport: false),
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
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                          tooltip: 'Edit Farmer',
                          onPressed: () => _showEditFarmerDialog(context, service, farmer),
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
  // MODULE 6: ADMIN ACCOUNTS
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
              Wrap(
                spacing: 8,
                children: [
                  _buildExportImportButtons(context, 'Admin Accounts', locale, service),
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
  // MODULE 7: ACTIVITY LOG
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
              _buildExportImportButtons(context, 'Activity Log Audit', locale, service),
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
