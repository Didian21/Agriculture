import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf_lib;
import 'package:pdf/widgets.dart' as pw;
import 'account_service.dart';

class PdfExportService {
  static Future<Uint8List> generateStyledPdfBytes(String moduleName, AccountService service) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(now);
    final operatorName = service.activeUserName.isNotEmpty ? service.activeUserName : 'MAO Admin';
    final mod = moduleName.toLowerCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pdf_lib.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Pagsanjan Agricultural System', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.green800)),
                    pw.Text('Smart Farming. Brighter Tomorrow.', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: pdf_lib.PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: pdf_lib.PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text('MAO OFFICIAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.green800)),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: pdf_lib.PdfColors.green700, thickness: 2),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('AGRICULTURAL REPORT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.green900, letterSpacing: 1.2)),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Pagsanjan Municipal Agriculture Office (MAO)', style: pw.TextStyle(fontSize: 9, color: pdf_lib.PdfColors.grey600)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: pw.TextStyle(fontSize: 9, color: pdf_lib.PdfColors.grey600)),
          ],
        ),
        build: (context) {
          List<List<String>> tableData = [];
          List<String> headers = [];

          if (mod.contains('farmer') && mod.contains('farm')) {
            headers = ['No.', 'Farmer Name', 'Barangay', 'Crop Type', 'Area (ha)', 'Status'];
            int i = 1;
            for (final f in service.farmers) {
              final farmerFarms = service.farms.where((farm) => farm.farmerId == f.id || farm.farmerName == f.profileName).toList();
              if (farmerFarms.isEmpty) {
                tableData.add(['$i', f.profileName, f.barangay, 'N/A', '0.0', f.status]);
                i++;
              } else {
                for (final farm in farmerFarms) {
                  tableData.add(['$i', f.profileName, farm.barangay, farm.cropType, farm.landAreaHectares.toStringAsFixed(1), f.status]);
                  i++;
                }
              }
            }
          } else if (mod.contains('historical')) {
            headers = ['No.', 'Crop', 'Year', 'Month', 'Barangay', 'Production (MT)', 'Price/kg (PHP)'];
            int i = 1;
            for (final h in service.historicalRecords) {
              tableData.add(['$i', h.crop, '${h.year}', h.month, h.barangay, h.productionMT.toString(), 'P${h.pricePerKg.toStringAsFixed(2)}']);
              i++;
            }
          } else if (mod.contains('account')) {
            if (mod.contains('admin')) {
              headers = ['No.', 'Staff Name', 'Username', 'Email', 'Role', 'Status'];
              int i = 1;
              for (final s in service.adminStaffList) {
                tableData.add(['$i', s.name, s.username, s.email, s.role, s.status]);
                i++;
              }
            } else {
              headers = ['No.', 'Farmer Name', 'Username', 'Barangay', 'Contact', 'Status'];
              int i = 1;
              for (final f in service.farmers) {
                tableData.add(['$i', f.profileName, f.username, f.barangay, f.contactNumber, f.status]);
                i++;
              }
            }
          } else if (mod.contains('map')) {
            headers = ['No.', 'Farmer Name', 'Barangay', 'Area (ha)', 'Crop Type'];
            int i = 1;
            for (final farm in service.farms) {
              tableData.add(['$i', farm.farmerName, farm.barangay, farm.landAreaHectares.toStringAsFixed(1), farm.cropType]);
              i++;
            }
          } else if (mod.contains('activity') || mod.contains('log')) {
            headers = ['No.', 'Timestamp', 'Operator', 'Module', 'Action', 'Details'];
            int i = 1;
            for (final l in service.activityLogs) {
              tableData.add(['$i', DateFormat('MM-dd HH:mm').format(l.timestamp), l.user, l.module, l.action, l.details]);
              i++;
            }
          } else {
            headers = ['No.', 'Metric Title', 'Value', 'Description'];
            tableData.add(['1', 'Registered Farmers', service.farmers.length.toString(), 'Active Agricultural Directory']);
            final totalArea = service.farms.fold(0.0, (sum, item) => sum + item.landAreaHectares);
            tableData.add(['2', 'Total Farm Area (ha)', totalArea.toStringAsFixed(1), 'Pagsanjan Registered Farmlands']);
          }

          return [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: pdf_lib.PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: pdf_lib.PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Report Type    : ${moduleName.toUpperCase()}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Generated Date : $dateStr', style: const pw.TextStyle(fontSize: 11)),
                  pw.SizedBox(height: 4),
                  pw.Text('Generated By   : $operatorName', style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: tableData,
              border: pw.TableBorder.all(color: pdf_lib.PdfColors.green700, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: pdf_lib.PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.green800),
              cellHeight: 24,
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
              },
              oddRowDecoration: const pw.BoxDecoration(color: pdf_lib.PdfColors.grey50),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }
}
