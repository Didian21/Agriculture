import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../dashboard_data.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/farmer.dart';
import '../services/account_service.dart';
import 'dashboard/dashboard_screen.dart';
import 'map_screen.dart';

class FarmerLoginScreen extends StatefulWidget {
  final DashboardProvider p;
  const FarmerLoginScreen({super.key, required this.p});

  @override
  State<FarmerLoginScreen> createState() => _FarmerLoginScreenState();
}

class _FarmerLoginScreenState extends State<FarmerLoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  double calculatePolygonAreaSqM(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    const double radius = 6378137.0;
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      final lat1 = p1.latitude * math.pi / 180.0;
      final lat2 = p2.latitude * math.pi / 180.0;
      final lon1 = p1.longitude * math.pi / 180.0;
      final lon2 = p2.longitude * math.pi / 180.0;
      area += (lon2 - lon1) * (2.0 + math.sin(lat1) + math.sin(lat2));
    }
    area = (area * radius * radius / 2.0).abs();
    return area;
  }

  double calculatePolygonAreaHectares(List<LatLng> points) {
    return calculatePolygonAreaSqM(points) / 10000.0;
  }

  LatLng calculatePolygonCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(14.2790, 121.4550);
    double sumLat = 0;
    double sumLon = 0;
    for (final p in points) {
      sumLat += p.latitude;
      sumLon += p.longitude;
    }
    return LatLng(sumLat / points.length, sumLon / points.length);
  }

  bool _doPolygonsOverlap(List<LatLng> poly1, List<LatLng> poly2) {
    if (poly1.length < 3 || poly2.length < 3) return false;
    bool isPointInPoly(LatLng point, List<LatLng> poly) {
      bool inside = false;
      int j = poly.length - 1;
      for (int i = 0; i < poly.length; i++) {
        final pi = poly[i];
        final pj = poly[j];
        if ((pi.longitude > point.longitude) != (pj.longitude > point.longitude) &&
            (point.latitude < (pj.latitude - pi.latitude) * (point.longitude - pi.longitude) / (pj.longitude - pi.longitude) + pi.latitude)) {
          inside = !inside;
        }
        j = i;
      }
      return inside;
    }
    for (final p in poly1) {
      if (isPointInPoly(p, poly2)) return true;
    }
    for (final p in poly2) {
      if (isPointInPoly(p, poly1)) return true;
    }
    return false;
  }

  FarmRecord? findOverlappingFarm(List<LatLng> boundaryPoints, List<FarmRecord> allFarms) {
    if (boundaryPoints.length < 3) return null;
    for (final farm in allFarms) {
      if (farm.boundaryPoints.length >= 3) {
        if (_doPolygonsOverlap(boundaryPoints, farm.boundaryPoints)) {
          return farm;
        }
      }
    }
    return null;
  }

  Future<void> _login() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mangyaring ilagay ang iyong Username at Password')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.leaf)),
    );

    final accountService = Provider.of<AccountService>(context, listen: false);

    // Load real-time status from Supabase database
    await accountService.loadFromSupabase(silent: true);

    final farmer = await accountService.authenticateFarmerAsync(username, password);

    if (!mounted) return;
    Navigator.pop(context); // Pop loading

    if (farmer != null) {
      if (farmer.status == 'Pending') {
        _showPendingApprovalDialog();
        return;
      }
      widget.p.login(username: farmer.username, phone: farmer.contactNumber);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      final matchPending = accountService.pendingFarmers.where(
        (f) => f.username.trim().toLowerCase() == username.toLowerCase() ||
            (f.contactNumber.replaceAll(RegExp(r'\D'), '').isNotEmpty && f.contactNumber.replaceAll(RegExp(r'\D'), '') == username.replaceAll(RegExp(r'\D'), '')),
      );

      if (matchPending.isNotEmpty) {
        _showPendingApprovalDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mali ang Username o Password. Pakisuri ang iyong credentials sa Supabase.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Pending Account Approval', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          '⏳ Ang inyong rehistrasyon ay kasalukuyang nakabinbin pa para sa kumpirmasyon ng Municipal Agriculture Office (MAO) Admin sa Pagsanjan.\n\nMakakapag-login lamang kayo kapag na-approve na ng Admin ang inyong akawnt.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Naiintindihan Ko'),
          ),
        ],
      ),
    );
  }

  void _showRegisterDialog() {
    final accountService = Provider.of<AccountService>(context, listen: false);
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final landAreaCtrl = TextEditingController(text: '1.0');
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    final specificCropCtrl = TextEditingController();
    final empSearchCtrl = TextEditingController();

    String selectedBrgy = 'Biñan';
    String selectedOrg = 'Choose Association';
    String selectedTenure = 'Owner';
    bool obscurePass = true;
    final Set<String> selectedPrimaryCrops = {'Rice'};
    final List<String> specificCropsList = [];
    final List<LatLng> boundaryPoints = [];
    String? dialogError;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          backgroundColor: const Color(0xFFF8FCF5),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF166534),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Farmer Account Registration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 580,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                      child: Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),

                  // SECTION 1: FARMER ACCOUNT INFORMATION
                  const Row(
                    children: [
                      Icon(Icons.badge_rounded, size: 16, color: Color(0xFF166534)),
                      SizedBox(width: 6),
                      Text(
                        'FARMER ACCOUNT INFORMATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Full Personal Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: usernameCtrl,
                          decoration: InputDecoration(
                            hintText: 'Username',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: passCtrl,
                          obscureText: obscurePass,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(obscurePass ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 18),
                              onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: AccountService.pagsanjanBarangays.contains(selectedBrgy) ? selectedBrgy : AccountService.pagsanjanBarangays.first,
                          decoration: InputDecoration(
                            labelText: 'Barangay',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: AccountService.pagsanjanBarangays.map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(b, overflow: TextOverflow.ellipsis, maxLines: 1),
                          )).toList(),
                          onChanged: (val) => setDialogState(() => selectedBrgy = val ?? 'Biñan'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                          decoration: InputDecoration(
                            hintText: 'Contact Number (Optional)',
                            helperText: 'Optional: 11 digits if provided (e.g. 09123456789)',
                            helperStyle: const TextStyle(fontSize: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: (['Choose Association', 'Not Associated', ...accountService.getUniqueOrganizations()].contains(selectedOrg))
                        ? selectedOrg
                        : 'Choose Association',
                    decoration: InputDecoration(
                      labelText: 'Association / Organization',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: ['Choose Association', 'Not Associated', ...accountService.getUniqueOrganizations()].map((org) => DropdownMenuItem(
                      value: org,
                      child: Text(org, overflow: TextOverflow.ellipsis, maxLines: 1),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedOrg = val ?? 'Choose Association'),
                  ),

                  const Divider(height: 28),

                  // SECTION 2: FARM LAND & CROP INFORMATION
                  const Row(
                    children: [
                      Icon(Icons.agriculture_rounded, size: 16, color: Color(0xFF166534)),
                      SizedBox(width: 6),
                      Text(
                        'FARM LAND & CROP INFORMATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Primary Crop Types (Select all that apply):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('Rice', '🌾 Rice'),
                      ('Vegetables', '🥬 Vegetables'),
                      ('Fruits', '🍎 Fruits'),
                    ].map((item) {
                      final isSel = selectedPrimaryCrops.contains(item.$1);
                      return FilterChip(
                        label: Text(item.$2, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? const Color(0xFF166534) : Colors.black87)),
                        selected: isSel,
                        selectedColor: const Color(0xFFDCFCE7),
                        backgroundColor: const Color(0xFFF0FDF4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSel ? const Color(0xFF166534) : Colors.grey.shade300)),
                        onSelected: (val) {
                          setDialogState(() {
                            if (val) {
                              selectedPrimaryCrops.add(item.$1);
                            } else if (selectedPrimaryCrops.length > 1) {
                              selectedPrimaryCrops.remove(item.$1);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('SPECIFIC CROP TYPES & VARIETIES (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: specificCropCtrl,
                          decoration: InputDecoration(
                            hintText: 'Type specific crop (e.g. Mango, Banana, Eggplant, NS...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: const Color(0xFF166534),
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: const Icon(Icons.add_rounded, color: Colors.white),
                          onPressed: () {
                            final text = specificCropCtrl.text.trim();
                            if (text.isNotEmpty && !specificCropsList.contains(text)) {
                              setDialogState(() {
                                specificCropsList.add(text);
                                specificCropCtrl.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (specificCropsList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: specificCropsList.map((item) => Chip(
                        label: Text(item, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                        backgroundColor: const Color(0xFFF0FDF4),
                        deleteIcon: const Icon(Icons.cancel, size: 16, color: Color(0xFF166534)),
                        onDeleted: () => setDialogState(() => specificCropsList.remove(item)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF86EFAC))),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: landAreaCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Land Area (ha)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: selectedTenure,
                          decoration: InputDecoration(
                            labelText: 'Tenure Status',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: ['Owner', 'Tenant', 'Lease', 'CLT', 'Hired Farmworkers', 'Not Employed'].map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t, overflow: TextOverflow.ellipsis, maxLines: 1),
                          )).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedTenure = val ?? 'Owner';
                              if (selectedTenure == 'Not Employed') {
                                landAreaCtrl.text = '0.0';
                                addressCtrl.text = 'Not Employed / Independent';
                                latCtrl.text = '14.2790';
                                lonCtrl.text = '121.4550';
                                boundaryPoints.clear();
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (selectedTenure == 'Hired Farmworkers') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: empSearchCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Search Employer / Landowner',
                        hintText: 'Type employer name...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFEFF6FF),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF0056B3)),
                        suffixIcon: empSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () => setDialogState(() => empSearchCtrl.clear()),
                              )
                            : null,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Select Employer (Current Landowner / Tenant)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFEFF6FF),
                        prefixIcon: const Icon(Icons.person_pin_rounded, color: Color(0xFF0056B3)),
                      ),
                      items: () {
                        final list = accountService.farmers.where((f) {
                          if (f.profileName.trim().isEmpty) return false;
                          final q = empSearchCtrl.text.trim().toLowerCase();
                          return q.isEmpty ||
                              f.profileName.toLowerCase().contains(q) ||
                              f.username.toLowerCase().contains(q) ||
                              f.barangay.toLowerCase().contains(q);
                        }).toList();

                        if (list.isEmpty) {
                          return [
                            const DropdownMenuItem(
                              value: 'NONE',
                              child: Text('No employer found', style: TextStyle(color: Colors.grey)),
                            ),
                          ];
                        }

                        return list.map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Text('${f.profileName} (${f.barangay})', overflow: TextOverflow.ellipsis, maxLines: 1),
                        )).toList();
                      }(),
                      onChanged: (empId) {
                        if (empId != null && empId != 'NONE') {
                          setDialogState(() {
                            final empFarmer = accountService.farmers.firstWhere((f) => f.id == empId, orElse: () => accountService.farmers.first);
                            final empFarm = accountService.farms.firstWhere(
                              (farm) => farm.farmerId == empId || farm.farmerName == empFarmer.profileName,
                              orElse: () => FarmRecord(
                                id: 'AUTO_FARM',
                                farmerId: empFarmer.id,
                                farmerName: empFarmer.profileName,
                                locationName: 'Sitio ${empFarmer.barangay}',
                                latitude: 14.2790,
                                longitude: 121.4550,
                                landAreaHectares: 2.0,
                                tenureStatus: 'Owner',
                                cropType: 'Rice',
                                barangay: empFarmer.barangay,
                              ),
                            );

                            landAreaCtrl.text = empFarm.landAreaHectares.toStringAsFixed(1);
                            selectedBrgy = empFarm.barangay;
                            addressCtrl.text = empFarm.locationName.trim().isNotEmpty
                                ? empFarm.locationName
                                : 'Brgy. ${empFarm.barangay}, Pagsanjan';
                            latCtrl.text = empFarm.latitude.toStringAsFixed(5);
                            lonCtrl.text = empFarm.longitude.toStringAsFixed(5);
                            boundaryPoints.clear();
                            if (empFarm.boundaryPoints.isNotEmpty) {
                              boundaryPoints.addAll(empFarm.boundaryPoints);
                            }
                          });
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      hintText: 'Complete Address / Farm Location',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      prefixIcon: const Icon(Icons.home_work_rounded, color: Color(0xFF166534)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

              ],
            ),
          ),
        ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF166534),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Submit Registration', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final nameVal = nameCtrl.text.trim();
                final userVal = usernameCtrl.text.trim();
                final phoneVal = phoneCtrl.text.trim();
                final passVal = passCtrl.text.trim();

                if (nameVal.isEmpty || userVal.isEmpty || passVal.isEmpty) {
                  setDialogState(() => dialogError = 'Please fill in Name, Username, and Password!');
                  return;
                }

                if (phoneVal.isNotEmpty && phoneVal.length != 11) {
                  setDialogState(() => dialogError = 'Phone Number must be exactly 11 digits!');
                  return;
                }

                final existingUser = accountService.farmers.any((f) => f.username.toLowerCase() == userVal.toLowerCase());
                if (existingUser) {
                  setDialogState(() => dialogError = 'Username "@$userVal" is already registered!');
                  return;
                }

                final finalOrg = selectedOrg == 'Choose Association' ? 'Not Associated' : selectedOrg;

                final farmerId = await accountService.registerFarmer(
                  username: userVal,
                  password: passVal,
                  profileName: nameVal,
                  barangay: selectedBrgy,
                  contactNumber: phoneVal.isEmpty ? 'N/A' : phoneVal,
                  organization: finalOrg,
                );

                final primaryCropsStr = selectedPrimaryCrops.join(', ');
                final specificCropsStr = specificCropsList.isNotEmpty ? specificCropsList.join(', ') : primaryCropsStr;
                final finalCropType = '$primaryCropsStr ($specificCropsStr)';
                final farmLocName = addressCtrl.text.trim().isEmpty ? 'Farm Lot, Brgy. $selectedBrgy, Pagsanjan' : addressCtrl.text.trim();

                // Save pending farm record (without boundary points - technician will plot and assign soil type during visit)
                await accountService.addFarmRecord(
                  farmerId: farmerId,
                  farmerName: nameVal,
                  locationName: farmLocName,
                  latitude: 14.2790,
                  longitude: 121.4550,
                  landAreaHectares: double.tryParse(landAreaCtrl.text) ?? 1.0,
                  tenureStatus: selectedTenure,
                  cropType: finalCropType,
                  barangay: selectedBrgy,
                  boundaryPoints: [],
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    useRootNavigator: true,
                    builder: (alertCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                          SizedBox(width: 8),
                          Text('Registration Submitted!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      content: Text(
                        '🎉 Thank you, $nameVal!\n\nYour registration and farm details have been submitted to the Pagsanjan Municipal Agriculture Office (MAO). An Admin will review and approve your account, after which a Technician will visit your farm to map your land boundary and record the soil type.',
                        style: const TextStyle(fontSize: 13.5, height: 1.4),
                      ),
                      actions: [
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
                          onPressed: () => Navigator.pop(alertCtx),
                          child: const Text('OK'),
                        ),
                      ],
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

    return Scaffold(
      backgroundColor: AppColors.paddy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PagriLogo(height: 100),
                const SizedBox(height: 20),
                const Text(
                  'PAGRI FARMER',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 2, color: AppColors.leaf),
                ),
                Text(
                  t.portalTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.signInTitle,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.signInHint,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _userCtrl,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_rounded, color: AppColors.leaf),
                            labelText: 'Username',
                            hintText: 'e.g. juandela',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.leaf),
                            labelText: 'Password',
                            hintText: 'Enter password',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.leaf,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _login,
                            icon: const Icon(Icons.login_rounded),
                            label: Text(
                              t.signIn,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: _showRegisterDialog,
                            icon: const Icon(Icons.how_to_reg_rounded, color: AppColors.leaf, size: 18),
                            label: const Text(
                              'Wala pang account? Mag-rehistro Dito',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.leaf, fontSize: 13.5),
                            ),
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
      ),
    );
  }
}
