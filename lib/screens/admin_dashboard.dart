import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/account_service.dart';
import '../models/farmer.dart';
import 'map_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // 0: Dashboard, 1: Farmers, 2: Crop Production, 3: Reports, 4: GIS Map
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _barangays = [];
  bool _isLoadingMap = true;
  bool _isTagalog = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadGeoJsonMap();
  }

  Future<void> _loadGeoJsonMap() async {
    try {
      final jsonString = await rootBundle.loadString('pagsanjanmapcipped.geojson');
      final data = json.decode(jsonString);
      final features = data['features'] as List;
      setState(() {
        _barangays = features.map((f) {
          final props = f['properties'] as Map<String, dynamic>;
          return {
            'name': props['NAME_3'] ?? 'Unknown',
            'type': props['TYPE_3'] ?? 'Barangay',
          };
        }).toList();
        _isLoadingMap = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  void _showCreateFarmerDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final landSizeController = TextEditingController();
    final cropController = TextEditingController();
    final locationController = TextEditingController();
    final contactController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isTagalog ? 'Magrehistro ng Magsasaka' : 'Register Farmer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: _isTagalog ? 'Pangalan ng Magsasaka' : 'Farmer Name')),
              TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              TextField(controller: landSizeController, decoration: const InputDecoration(labelText: 'Sukat ng Lupa (e.g., 2.5 ha)')),
              TextField(controller: cropController, decoration: const InputDecoration(labelText: 'Anong Inatanim (e.g., Rice)')),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Lokasyon / Barangay (e.g., Biñan)')),
              TextField(controller: contactController, decoration: const InputDecoration(labelText: 'Contact Number')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_isTagalog ? 'Kanselahin' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && usernameController.text.isNotEmpty) {
                Provider.of<AccountService>(context, listen: false).addFarmer(
                  username: usernameController.text,
                  password: passwordController.text,
                  profileName: nameController.text,
                  landSize: landSizeController.text.isNotEmpty ? landSizeController.text : '1.0 ha',
                  cropPlanted: cropController.text.isNotEmpty ? cropController.text : 'Rice',
                  location: locationController.text.isNotEmpty ? locationController.text : 'Pagsanjan',
                  contactNumber: contactController.text.isNotEmpty ? contactController.text : '09123456789',
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isTagalog ? 'Matagumpay na nairehistro ang magsasaka!' : 'Farmer registered successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3B2B)),
            child: Text(_isTagalog ? 'Rehistro' : 'Register', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isTagalog ? 'Gumawa ng Anunsyo / Post' : 'Create Announcement / Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: _isTagalog ? 'Pamagat ng Post' : 'Post Title')),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: InputDecoration(labelText: _isTagalog ? 'Nilalaman ng Post / Abiso' : 'Post Content / Advisory', alignLabelWithHint: true),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_isTagalog ? 'Kanselahin' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                Provider.of<AccountService>(context, listen: false).addPost(
                  titleController.text,
                  contentController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isTagalog ? 'Matagumpay na naipaskil ang anunsyo!' : 'Announcement posted successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
            child: Text(_isTagalog ? 'I-post' : 'Post', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMessagingDialog(BuildContext context) {
    final searchController = TextEditingController();
    final messageController = TextEditingController();
    String query = '';
    Farmer? selectedFarmer;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final accountService = Provider.of<AccountService>(context);
          final farmers = accountService.farmers.where((f) {
            return f.profileName.toLowerCase().contains(query.toLowerCase()) ||
                   f.username.toLowerCase().contains(query.toLowerCase());
          }).toList();

          return AlertDialog(
            title: Text(_isTagalog ? 'Magpadala ng Mensahe / Abiso' : 'Send Message / Advisory'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isTagalog ? '1. Hanapin at Piliin ang Magsasaka:' : '1. Search & Select Farmer:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    onChanged: (val) => setStateDialog(() => query = val),
                    decoration: InputDecoration(
                      hintText: _isTagalog ? 'Hanapin ang pangalan...' : 'Search farmer name...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: farmers.isEmpty
                        ? Center(child: Text(_isTagalog ? 'Walang nakitang magsasaka' : 'No farmers found', style: const TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: farmers.length,
                            itemBuilder: (context, index) {
                              final farmer = farmers[index];
                              final isSelected = selectedFarmer == farmer;
                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: Colors.blue.shade50,
                                leading: const Icon(Icons.person, size: 20, color: Color(0xFF0056B3)),
                                title: Text(farmer.profileName),
                                subtitle: Text('@${farmer.username}'),
                                trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF0056B3), size: 18) : null,
                                onTap: () => setStateDialog(() => selectedFarmer = farmer),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(_isTagalog ? '2. Mag-type ng Mensahe:' : '2. Type Message:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: _isTagalog ? 'I-type ang mensahe dito...' : 'Type advisory or message here...',
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(_isTagalog ? 'Kanselahin' : 'Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (selectedFarmer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isTagalog ? 'Mangyaring pumili ng magsasaka.' : 'Please select a farmer recipient.')),
                    );
                    return;
                  }
                  if (messageController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isTagalog ? 'Mangyaring mag-type ng mensahe.' : 'Please enter a message.')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_isTagalog ? 'Matagumpay na naipadala ang mensahe kay ${selectedFarmer!.profileName}!' : 'Message sent successfully to ${selectedFarmer!.profileName}!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
                child: Text(_isTagalog ? 'Ipadala' : 'Send Message', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    final notifications = [
      {'title': _isTagalog ? 'Bagong Magsasaka' : 'New farmer registered', 'desc': 'Maria Santos registered from Brgy. Biñan', 'time': '2h ago', 'read': false},
      {'title': _isTagalog ? 'Na-export ang Ulat' : 'Report Exported', 'desc': 'Q3 agricultural report generated successfully', 'time': '1d ago', 'read': true},
      {'title': _isTagalog ? 'Naipadala ang Abiso' : 'Typhoon Advisory Sent', 'desc': 'Broadcasted to 1,284 farmers in Pagsanjan', 'time': '3d ago', 'read': true},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_isTagalog ? 'Mga Abiso' : 'Notifications', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isTagalog ? 'Lahat ng abiso ay binasa na' : 'All notifications marked as read')),
                );
              },
              child: Text(_isTagalog ? 'Markahan bilang nabasa' : 'Mark all as read', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 250,
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (notif['read'] as bool) ? Colors.grey.shade200 : Colors.blue.shade100,
                  child: Icon(
                    (notif['read'] as bool) ? Icons.notifications_none : Icons.notifications_active,
                    color: (notif['read'] as bool) ? Colors.grey : const Color(0xFF0056B3),
                    size: 18,
                  ),
                ),
                title: Text(notif['title'] as String, style: TextStyle(fontWeight: (notif['read'] as bool) ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif['desc'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(notif['time'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_isTagalog ? 'Isara' : 'Close')),
        ],
      ),
    );
  }

  void _showBarangaysListDialog(BuildContext context) {
    final pagsanjanBarangays = [
      {'name': 'Barangay I (Poblacion)', 'zone': 'Municipal Center', 'farmers': 45, 'crop': 'Commercial / Mixed'},
      {'name': 'Barangay II (Poblacion)', 'zone': 'Commercial Zone', 'farmers': 38, 'crop': 'Vegetables'},
      {'name': 'Alipit', 'zone': 'Upland Agricultural', 'farmers': 72, 'crop': 'Coconut & Fruit Trees'},
      {'name': 'Biñan', 'zone': 'Primary Agricultural Zone', 'farmers': 118, 'crop': 'Rice & Corn'},
      {'name': 'Buboy', 'zone': 'Riverbank Farming', 'farmers': 94, 'crop': 'Coconut & Banana'},
      {'name': 'Cabanbanan', 'zone': 'Lowland Farming', 'farmers': 85, 'crop': 'Rice'},
      {'name': 'Calusiche', 'zone': 'Agricultural Zone', 'farmers': 60, 'crop': 'Rice & Vegetables'},
      {'name': 'Dingin', 'zone': 'Rural Zone', 'farmers': 52, 'crop': 'Root Crops'},
      {'name': 'Guiha', 'zone': 'Agricultural Zone', 'farmers': 48, 'crop': 'Fruit Trees'},
      {'name': 'Lambac', 'zone': 'Rice Production Area', 'farmers': 135, 'crop': 'Rice'},
      {'name': 'Layugan', 'zone': 'Agricultural Zone', 'farmers': 41, 'crop': 'Corn & Vegetables'},
      {'name': 'Pinagsanjan', 'zone': 'Eco-Tourism & Farming', 'farmers': 105, 'crop': 'Mixed Crops'},
      {'name': 'Sabang', 'zone': 'Vegetable Farming Zone', 'farmers': 92, 'crop': 'Vegetables & Legumes'},
      {'name': 'San Isidro', 'zone': 'Agricultural Settlement', 'farmers': 78, 'crop': 'Rice & Coconut'},
      {'name': 'Sampaloc', 'zone': 'Upland Area', 'farmers': 35, 'crop': 'Fruit Trees'},
      {'name': 'Anibong', 'zone': 'Rural Area', 'farmers': 40, 'crop': 'Coconut'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_city, color: Color(0xFF0056B3)),
            const SizedBox(width: 8),
            Text(_isTagalog ? 'Pumili ng Barangay para i-filter' : 'Select Barangay to Filter'),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 400,
          child: ListView.builder(
            itemCount: pagsanjanBarangays.length,
            itemBuilder: (context, index) {
              final b = pagsanjanBarangays[index];
              final barangayName = b['name'] as String;
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = 1;
                      _searchQuery = barangayName;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isTagalog ? 'Naka-filter na sa $barangayName — Ipinapakita ang mga magsasaka.' : 'Filtered by $barangayName — Showing registered farmers.')),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: const Color(0xFF0056B3),
                    child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(barangayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${b['zone']} • ${b['crop']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text('${b['farmers']} ${_isTagalog ? "magsasaka" : "farmers"}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_isTagalog ? 'Isara' : 'Close')),
        ],
      ),
    );
  }

  void _showFarmerDetailsDialog(BuildContext context, Farmer farmer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF0056B3),
              child: Text('F', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(farmer.profileName, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${farmer.username}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${_isTagalog ? "Lokasyon" : "Location"}: ${farmer.location}'),
            Text('${_isTagalog ? "Sukat ng Lupa" : "Land Size"}: ${farmer.landSize}'),
            Text('${_isTagalog ? "Inatanim" : "Crop Planted"}: ${farmer.cropPlanted}'),
            Text('${_isTagalog ? "Contact Number" : "Contact Number"}: ${farmer.contactNumber}'),
            const SizedBox(height: 8),
            Text('${_isTagalog ? "Katayuan" : "Status"}: Active', style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 16),
            Text(_isTagalog ? 'Mga Rekord sa Agrikultura:' : 'Agricultural Records:', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (farmer.records.isEmpty)
              Text(_isTagalog ? 'Wala pang rekord.' : 'No records submitted yet.', style: const TextStyle(color: Colors.grey))
            else
              ...farmer.records.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(children: [const Icon(Icons.circle, size: 6, color: Color(0xFF0056B3)), const SizedBox(width: 6), Text(r)]),
              )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_isTagalog ? 'Isara' : 'Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    final sidebarContent = Container(
      width: 260,
      color: const Color(0xFF004080),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF004080),
                  child: Text('AD', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('Employee ID: Not set', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildNavItem(icon: Icons.dashboard, label: _isTagalog ? 'Dashboard' : 'Dashboard', index: 0),
          _buildNavItem(icon: Icons.people, label: _isTagalog ? 'Magsasaka' : 'Farmers', index: 1),
          _buildNavItem(icon: Icons.eco, label: _isTagalog ? 'Produksyon ng Pananim' : 'Crop production', index: 2),
          _buildNavItem(icon: Icons.assessment, label: _isTagalog ? 'Mga Ulat' : 'Reports', index: 3),
          _buildNavItem(icon: Icons.map, label: _isTagalog ? 'Mapa ng GIS' : 'GIS Map', index: 4),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateFarmerDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF004080),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(_isTagalog ? 'Magdagdag ng Magsasaka' : 'Add farmer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              icon: const Icon(Icons.logout, color: Colors.white70),
              label: Text(_isTagalog ? 'Mag-logout' : 'Logout', style: const TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );

    Widget mainContentArea;
    if (_selectedIndex == 0) {
      mainContentArea = _buildDashboardView();
    } else if (_selectedIndex == 1) {
      mainContentArea = _buildFarmersDirectoryView();
    } else if (_selectedIndex == 2) {
      mainContentArea = _buildCropProductionView();
    } else if (_selectedIndex == 3) {
      mainContentArea = _buildReportsView();
    } else {
      mainContentArea = const PagsanjanMapScreen();
    }

    final topHeader = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Row(
            children: [
              const Icon(Icons.home_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(_isTagalog ? 'Workspace' : 'Workspace', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              Text(_isTagalog ? ' / Pananaw' : ' / Overview', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
          const Spacer(),
          // Search Icon or Collapsible Search TextField
          if (!_isSearching)
            IconButton(
              onPressed: () => setState(() => _isSearching = true),
              icon: const Icon(Icons.search, size: 20, color: Colors.black87),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              tooltip: _isTagalog ? 'Maghanap' : 'Search',
            )
          else
            Container(
              width: 180,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _selectedIndex = 1;
                  });
                },
                decoration: InputDecoration(
                  hintText: _isTagalog ? 'Maghanap...' : 'Search...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isTagalog = !_isTagalog;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isTagalog ? 'Wika pinalitan sa Tagalog' : 'Language switched to English')),
              );
            },
            icon: const Icon(Icons.language, size: 16, color: Color(0xFF0056B3)),
            label: Text(_isTagalog ? 'TL' : 'EN', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showMessagingDialog(context),
            icon: const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.black87),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            tooltip: _isTagalog ? 'Mga Mensahe' : 'Messages',
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => _showNotificationsDialog(context),
            icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_outlined, size: 20)),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            tooltip: _isTagalog ? 'Mga Abiso' : 'Notifications',
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, size: 14, color: Color(0xFF1A3B2B)),
                const SizedBox(width: 6),
                Text(_isTagalog ? 'Admin' : 'Admin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3B2B))),
              ],
            ),
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
        backgroundColor: const Color(0xFFF7F9F6),
        body: Row(
          children: [
            sidebarContent,
            Expanded(child: fullBody),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF004080),
          foregroundColor: Colors.white,
          title: Text(_selectedIndex == 0 ? 'Admin Dashboard' : _selectedIndex == 1 ? 'Farmer Directory' : _selectedIndex == 2 ? 'Crop Production' : _selectedIndex == 3 ? 'Reports' : 'GIS Map', style: const TextStyle(fontSize: 18)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            ),
          ],
        ),
        drawer: Drawer(child: sidebarContent),
        body: fullBody,
      );
    }
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 20),
        title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
        dense: true,
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

  Widget _buildDashboardView() {
    return Consumer<AccountService>(
      builder: (context, accountService, child) {
        final farmers = accountService.farmers;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTagalog ? 'Pananaw sa Dashboard' : 'Dashboard overview',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isTagalog ? "Magandang araw, Admin. Narito ang buod ng komunidad ng agrikultura." : "Welcome back, Maria. Here's your agricultural community at a glance.",
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showCreatePostDialog(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.post_add, size: 14),
                              label: Text(_isTagalog ? 'Post' : 'Create Post', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_isTagalog ? 'Matagumpay na na-export ang ulat!' : 'Report exported successfully!')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.download, size: 14),
                              label: Text(_isTagalog ? 'Export' : 'Export report', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateFarmerDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A3B2B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.add, size: 14),
                              label: Text(_isTagalog ? 'Rehistro' : 'Register farmer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTagalog ? 'Pananaw sa Dashboard' : 'Dashboard overview',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isTagalog ? "Magandang araw, Admin." : "Welcome back, Maria.",
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showCreatePostDialog(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.post_add, size: 14),
                              label: Text(_isTagalog ? 'Post' : 'Post', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_isTagalog ? 'Matagumpay na na-export ang ulat!' : 'Report exported successfully!')),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.download, size: 14),
                              label: Text(_isTagalog ? 'Export' : 'Export', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showCreateFarmerDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A3B2B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.add, size: 14),
                              label: Text(_isTagalog ? 'Rehistro' : 'Register', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // Filter Dropdowns & Snapshot Note
              LayoutBuilder(
                builder: (context, constraints) {
                  final isVerySmall = constraints.maxWidth < 450;
                  return Flex(
                    direction: isVerySmall ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: isVerySmall ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_isTagalog ? 'Napiling Quarter: Q3 2026' : 'Quarter filter selected: Q3 2026')),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text('Q3 2026', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showBarangaysListDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(_isTagalog ? 'Lahat ng Brgy (16)' : 'All Brgys (16)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isVerySmall)
                        Text(_isTagalog ? 'Snapshot: Sep 30, 2026' : 'Snapshot: Sep 30, 2026', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // 4 Core Enterprise Stats Cards (Fully responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final isMobileSmall = constraints.maxWidth < 450;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : (isMobileSmall ? 1 : 2),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isMobileSmall ? 2.4 : 1.25,
                    children: [
                      _buildEnterpriseStatCard(
                        title: _isTagalog ? 'KABUUANG MAGSASAKA' : 'Total registered farmers',
                        value: '${farmers.length}',
                        subtitle: _isTagalog ? '+66 ngayong quarter' : '+66 this quarter',
                        icon: Icons.people_outline,
                      ),
                      _buildEnterpriseStatCard(
                        title: _isTagalog ? 'KABUUANG LUPA' : 'Total agricultural areas',
                        value: '326',
                        subtitle: _isTagalog ? '2,460 ha rehistrado' : '2,460 ha registered',
                        icon: Icons.map_outlined,
                      ),
                      _buildEnterpriseStatCard(
                        title: _isTagalog ? 'URI NG PANANIM' : 'Total crop types',
                        value: '18',
                        subtitle: _isTagalog ? '4 grupo sa munisipyo' : '4 crop groups',
                        icon: Icons.eco_outlined,
                      ),
                      _buildEnterpriseStatCard(
                        title: _isTagalog ? 'KABUUANG PRODUKSYON' : 'Total production',
                        value: '18,450 t',
                        subtitle: _isTagalog ? '+9.8% vs Q2 ani' : '+9.8% vs Q2 harvest',
                        icon: Icons.agriculture_outlined,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Weather Forecast Card for Pagsanjan
              _buildWeatherCard(),
              const SizedBox(height: 20),

              // Agricultural Statistics Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isTagalog ? 'Estadistika sa Agrikultura' : 'Agricultural statistics', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                    const SizedBox(height: 4),
                    Text(_isTagalog ? 'Pamamahagi ng produksyon (MT)' : 'Production distribution (MT)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 16),
                    _buildStatBar('Rice (18 MT)', 18, 20, Colors.green),
                    _buildStatBar('Coconut (12 MT)', 12, 20, Colors.brown),
                    _buildStatBar('Banana (8 MT)', 8, 20, Colors.amber),
                    _buildStatBar('Vegetables (6 MT)', 6, 20, Colors.lightGreen),
                    _buildStatBar('Corn (5 MT)', 5, 20, Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Recent registrations section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
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
                            Text(_isTagalog ? 'Bagong Rehistro' : 'Recent registrations', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                            const SizedBox(height: 2),
                            Text(_isTagalog ? 'Mga huling rehistradong magsasaka' : 'Latest registered farmers', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedIndex = 1),
                          child: Text(_isTagalog ? 'Lahat' : 'View all', style: const TextStyle(color: Color(0xFF0056B3), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (farmers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(child: Text(_isTagalog ? 'Wala pang rehistradong magsasaka.' : 'No farmers registered yet.', style: const TextStyle(color: Colors.grey))),
                      )
                    else
                      ...farmers.take(4).map((farmer) => InkWell(
                        onTap: () => _showFarmerDetailsDialog(context, farmer),
                        child: _buildFarmerRow(farmer.profileName, '${_isTagalog ? "Brgy" : "Location"}: ${farmer.location} • ${_isTagalog ? "Tanim" : "Crop"}: ${farmer.cropPlanted}', farmer.profileName.isNotEmpty ? farmer.profileName[0].toUpperCase() : 'F', 'Active'),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Pagsanjan Municipal GIS Map Launcher Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isTagalog ? 'Mapa ng Pagsanjan (GIS)' : 'Pagsanjan Municipal GIS Map', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 4),
                    icon: const Icon(Icons.fullscreen, size: 14),
                    label: Text(_isTagalog ? 'Buong Mapa' : 'Open Full Map', style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _selectedIndex = 4),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map, size: 40, color: Color(0xFF0056B3)),
                        const SizedBox(height: 6),
                        Text(_isTagalog ? 'I-click para buksan ang interactive GIS map' : 'Click to open interactive GIS map', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isTagalog ? 'I-click ang Barangay para i-filter:' : 'Click Barangay to filter registered members:', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    _isLoadingMap
                        ? const Center(child: CircularProgressIndicator())
                        : Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _barangays.map((b) => ActionChip(
                              avatar: const Icon(Icons.location_on, size: 12, color: Color(0xFF0056B3)),
                              label: Text(b['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              backgroundColor: Colors.blue.shade50,
                              onPressed: () {
                                final bName = b['name'] as String;
                                setState(() {
                                  _selectedIndex = 1;
                                  _searchQuery = bName;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_isTagalog ? 'Naka-filter na sa $bName' : 'Filtered by $bName')),
                                );
                              },
                            )).toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Municipal Announcements & Posts Section
              Text(_isTagalog ? 'Mga Anunsyo at Abiso' : 'Office Announcements', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
              const SizedBox(height: 10),
              if (accountService.posts.isEmpty)
                Text(_isTagalog ? 'Wala pang post.' : 'No posts yet.', style: const TextStyle(color: Colors.grey))
              else
                ...accountService.posts.map((post) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              post['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0056B3)),
                            ),
                          ),
                          Text(post['date'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        post['content'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                      ),
                    ],
                  ),
                )),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'AgriSupport · Pagsanjan Municipal Agriculture Office',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFarmersDirectoryView() {
    return Consumer<AccountService>(
      builder: (context, accountService, child) {
        final farmers = accountService.farmers.where((f) {
          final q = _searchQuery.toLowerCase();
          return f.profileName.toLowerCase().contains(q) || f.username.toLowerCase().contains(q) || f.location.toLowerCase().contains(q);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isTagalog ? 'PAMAMAHALA NG REKORD' : 'RECORD MANAGEMENT',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isTagalog ? 'Direktoryo ng Magsasaka' : 'Farmer directory',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_isTagalog ? 'Rehistradong magsasaka' : 'Registered farmers', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                          child: Text('${farmers.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: _isTagalog ? 'Hanapin ang pangalan o barangay' : 'Search name or barangay',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (farmers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(child: Text(_isTagalog ? 'Walang nahanap na magsasaka.' : 'No farmers found.', style: const TextStyle(color: Colors.grey))),
                      )
                    else
                      ...farmers.map((farmer) => Card(
                        elevation: 0,
                        color: Colors.grey.shade50,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.shade200)),
                        child: ListTile(
                          onTap: () => _showFarmerDetailsDialog(context, farmer),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            foregroundColor: const Color(0xFF0056B3),
                            child: Text(farmer.profileName.isNotEmpty ? farmer.profileName[0].toUpperCase() : 'F', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          title: Text(farmer.profileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0056B3))),
                          subtitle: Text('${_isTagalog ? "Brgy" : "Location"}: ${farmer.location} • ${_isTagalog ? "Tanim" : "Crop"}: ${farmer.cropPlanted}', style: const TextStyle(fontSize: 11)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Text(_isTagalog ? 'Aktibo' : 'Active', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                          ),
                        ),
                      )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCropProductionView() {
    final crops = [
      {'crop': 'Rice', 'production': '18 MT', 'area': '4 ha', 'season': 'Wet season', 'status': 'Current', 'color': Colors.blue},
      {'crop': 'Coconut', 'production': '12 MT', 'area': '2 ha', 'season': 'Year-round', 'status': 'Current', 'color': Colors.brown},
      {'crop': 'Banana', 'production': '8 MT', 'area': '1 ha', 'season': 'Year-round', 'status': 'Current', 'color': Colors.amber},
      {'crop': 'Vegetables', 'production': '6 MT', 'area': '1 ha', 'season': 'Dry season', 'status': 'For review', 'color': Colors.lightGreen},
      {'crop': 'Corn', 'production': '5 MT', 'area': '1.5 ha', 'season': 'Dry season', 'status': 'For review', 'color': Colors.orange},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isTagalog ? 'Produksyon ng pananim' : 'Crop production',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isTagalog ? 'Tantiya ng Produksyon (Pagsanjan)' : 'Production estimates (Pagsanjan)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                const SizedBox(height: 12),
                ...crops.map((c) => Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.eco, size: 16, color: c['color'] as Color),
                          const SizedBox(width: 8),
                          Text(c['crop'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0056B3))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(c['production'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${c['area']} • ${c['season']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isTagalog ? 'Mga Ulat at Analitika' : 'Municipal Reports & Analytics', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isTagalog ? 'Mga Magagamit na Ulat' : 'Available Reports', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                const SizedBox(height: 12),
                _buildReportTile(_isTagalog ? 'Buod ng Produksyon Q3 2026' : 'Q3 2026 Production Summary', 'PDF · 2.4 MB', Icons.picture_as_pdf),
                const Divider(),
                _buildReportTile(_isTagalog ? 'Direktoryo ng Magsasaka' : 'Farmers Directory', 'CSV · 450 KB', Icons.table_chart),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile(String title, String subtitle, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade50,
        child: Icon(icon, color: const Color(0xFF0056B3), size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isTagalog ? 'Na-download ang ulat!' : 'Report downloaded successfully!')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0056B3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        child: Text(_isTagalog ? 'I-export' : 'Export', style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildEnterpriseStatCard({
    required String title,
    required String value,
    required String subtitle,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 16, color: Colors.grey.shade600),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    final twoWeeksForecast = [
      {'day': _isTagalog ? 'Ngayon' : 'Today', 'temp': '29°/24°', 'cond': _isTagalog ? 'Araw' : 'Sunny', 'icon': Icons.wb_sunny},
      {'day': _isTagalog ? 'Lun' : 'Mon', 'temp': '28°/23°', 'cond': _isTagalog ? 'Maulap' : 'Cloudy', 'icon': Icons.cloud_outlined},
      {'day': _isTagalog ? 'Mar' : 'Tue', 'temp': '27°/23°', 'cond': _isTagalog ? 'Ulan' : 'Rain', 'icon': Icons.umbrella_outlined},
      {'day': _isTagalog ? 'Miy' : 'Wed', 'temp': '26°/22°', 'cond': _isTagalog ? 'Bagyo' : 'Storm', 'icon': Icons.thunderstorm_outlined},
      {'day': _isTagalog ? 'Huw' : 'Thu', 'temp': '28°/23°', 'cond': _isTagalog ? 'Araw' : 'Sunny', 'icon': Icons.wb_sunny},
      {'day': _isTagalog ? 'Biy' : 'Fri', 'temp': '29°/24°', 'cond': _isTagalog ? 'Alinsangan' : 'Humid', 'icon': Icons.wb_sunny_outlined},
      {'day': _isTagalog ? 'Sab' : 'Sat', 'temp': '27°/22°', 'cond': _isTagalog ? 'Ulan' : 'Rain', 'icon': Icons.umbrella_outlined},
      {'day': _isTagalog ? 'Lin' : 'Sun', 'temp': '28°/23°', 'cond': _isTagalog ? 'Maulap' : 'Cloudy', 'icon': Icons.cloud_outlined},
      {'day': _isTagalog ? 'Lun' : 'Mon', 'temp': '29°/24°', 'cond': _isTagalog ? 'Araw' : 'Sunny', 'icon': Icons.wb_sunny},
      {'day': _isTagalog ? 'Mar' : 'Tue', 'temp': '30°/25°', 'cond': _isTagalog ? 'Araw' : 'Sunny', 'icon': Icons.wb_sunny},
      {'day': _isTagalog ? 'Miy' : 'Wed', 'temp': '27°/23°', 'cond': _isTagalog ? 'Ulan' : 'Rain', 'icon': Icons.umbrella_outlined},
      {'day': _isTagalog ? 'Huw' : 'Thu', 'temp': '26°/22°', 'cond': _isTagalog ? 'Bagyo' : 'Storm', 'icon': Icons.thunderstorm_outlined},
      {'day': _isTagalog ? 'Biy' : 'Fri', 'temp': '28°/23°', 'cond': _isTagalog ? 'Maulap' : 'Cloudy', 'icon': Icons.cloud_outlined},
      {'day': _isTagalog ? 'Sab' : 'Sat', 'temp': '29°/24°', 'cond': _isTagalog ? 'Araw' : 'Sunny', 'icon': Icons.wb_sunny},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(_isTagalog ? 'Pagsanjan 2-Linggong Panahon' : 'Pagsanjan 2-Week Weather', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text(_isTagalog ? '14-Araw' : '14-Day', style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: twoWeeksForecast.length,
              itemBuilder: (context, index) {
                final f = twoWeeksForecast[index];
                return Container(
                  width: 68,
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(f['day'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Icon(f['icon'] as IconData, color: Colors.amberAccent, size: 18),
                      const SizedBox(height: 3),
                      Text(f['temp'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(f['cond'] as String, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double value, double max, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
              Text('${(value / max * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / max,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerRow(String name, String details, String initials, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade200,
            foregroundColor: const Color(0xFF0056B3),
            child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0056B3)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text(details, style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Color(0xFF0056B3))),
          ),
        ],
      ),
    );
  }
}
