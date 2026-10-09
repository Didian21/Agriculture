import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/account_service.dart';
import '../models/farmer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0; // 0: Dashboard, 1: Farmers, 2: Crop Production, 3: Reports
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showCreateFarmerDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Farmer Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Username')),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && usernameController.text.isNotEmpty) {
                Provider.of<AccountService>(context, listen: false).addFarmer(
                  usernameController.text,
                  passwordController.text,
                  nameController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Farmer account created successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
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
        title: const Text('Create Announcement / Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Post Title')),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Post Content / Advisory', alignLabelWithHint: true),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                Provider.of<AccountService>(context, listen: false).addPost(
                  titleController.text,
                  contentController.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement posted successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
            child: const Text('Post', style: TextStyle(color: Colors.white)),
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
            title: const Text('Send Message / Advisory'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. Search & Select Farmer:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    onChanged: (val) => setStateDialog(() => query = val),
                    decoration: InputDecoration(
                      hintText: 'Search farmer name...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: farmers.isEmpty
                        ? const Center(child: Text('No farmers found', style: TextStyle(color: Colors.grey)))
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
                  const Text('2. Type Message:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Type advisory or message here...',
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (selectedFarmer == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a farmer recipient.')),
                    );
                    return;
                  }
                  if (messageController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a message.')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Message sent successfully to ${selectedFarmer!.profileName}!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3)),
                child: const Text('Send Message', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
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
            const SizedBox(height: 8),
            const Text('Status: Active', style: TextStyle(color: Colors.green)),
            const SizedBox(height: 16),
            const Text('Agricultural Records:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (farmer.records.isEmpty)
              const Text('No records submitted yet.', style: TextStyle(color: Colors.grey))
            else
              ...farmer.records.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(children: [const Icon(Icons.circle, size: 6, color: Color(0xFF0056B3)), const SizedBox(width: 6), Text(r)]),
              )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
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
          _buildNavItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
          _buildNavItem(icon: Icons.people, label: 'Farmers', index: 1),
          _buildNavItem(icon: Icons.eco, label: 'Crop production', index: 2),
          _buildNavItem(icon: Icons.assessment, label: 'Reports', index: 3),
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
                label: const Text('Add farmer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              icon: const Icon(Icons.logout, color: Colors.white70),
              label: const Text('Logout', style: TextStyle(color: Colors.white70)),
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
    } else {
      mainContentArea = _buildPlaceholderView('Reports & Analytics', Icons.assessment);
    }

    final topHeader = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset('Pagri.jpg', width: 24, height: 24, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Municipal Agriculture Office / ${_selectedIndex == 0 ? "Overview" : _selectedIndex == 1 ? "Farmers" : _selectedIndex == 2 ? "Crop production" : "Reports"}',
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showMessagingDialog(context),
            icon: const Badge(child: Icon(Icons.mail_outline, size: 20)),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE2E8F0),
            child: Text('AD', style: TextStyle(color: Color(0xFF0056B3), fontWeight: FontWeight.bold, fontSize: 12)),
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
          title: Text(_selectedIndex == 0 ? 'Admin Dashboard' : _selectedIndex == 1 ? 'Farmer Directory' : _selectedIndex == 2 ? 'Crop Production' : 'Reports', style: const TextStyle(fontSize: 18)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADMIN OVERVIEW',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Good day, Admin ',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
                            ),
                            Text('👋', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Here's what's happening in Pagsanjan agriculture today.",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showCreatePostDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0056B3),
                      side: const BorderSide(color: Color(0xFF0056B3)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.post_add, size: 16),
                    label: const Text('Create Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero Banner Card
              InkWell(
                onTap: () => setState(() => _selectedIndex = 1),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('PAGSANJAN, LAGUNA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Growing a stronger agricultural community.',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Keep farmer records and local production data organized.',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                Text('View farmer directory', style: TextStyle(color: Color(0xFF0056B3), fontWeight: FontWeight.bold, fontSize: 13)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0056B3)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.agriculture, size: 64, color: Color(0xFF90CAF9)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent Farmer Records Section
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Recent farmer records', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                            SizedBox(height: 2),
                            Text('Latest registered farmers', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedIndex = 1),
                          child: const Text('View all', style: TextStyle(color: Color(0xFF0056B3), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (farmers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No farmers registered yet.', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ...farmers.take(4).map((farmer) => InkWell(
                        onTap: () => _showFarmerDetailsDialog(context, farmer),
                        child: _buildFarmerRow(farmer.profileName, 'Username: ${farmer.username} • Records: ${farmer.records.length}', farmer.profileName.isNotEmpty ? farmer.profileName[0].toUpperCase() : 'F', 'Active'),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Municipal Announcements & Posts Section
              const Text('Office Announcements & Posts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
              const SizedBox(height: 10),
              if (accountService.posts.isEmpty)
                const Text('No posts yet.', style: TextStyle(color: Colors.grey))
              else
                ...accountService.posts.map((post) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage('Pagri.jpg'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.75),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                post['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                            ),
                            Text(
                              post['date'] ?? '',
                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post['content'] ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                )),
              const SizedBox(height: 20),

              // Footer Notice
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dashboard figures are sample data for the initial admin interface.',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
          return f.profileName.toLowerCase().contains(q) || f.username.toLowerCase().contains(q);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECORD MANAGEMENT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Farmer directory',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage farmer profiles registered in Pagsanjan.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                      children: [
                        const Text('Registered farmers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                          child: Text('${farmers.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Search and review farmer information', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search name or username',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('FARMER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                          Expanded(flex: 2, child: Text('BARANGAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                          Expanded(flex: 2, child: Text('PRIMARY CROP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                          Expanded(flex: 1, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (farmers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No farmers found.', style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ...farmers.map((farmer) => InkWell(
                        onTap: () => _showFarmerDetailsDialog(context, farmer),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.blue.shade100,
                                      foregroundColor: const Color(0xFF0056B3),
                                      child: Text(farmer.profileName.isNotEmpty ? farmer.profileName[0].toUpperCase() : 'F', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(farmer.profileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0056B3))),
                                          const Text('Farmer', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(flex: 2, child: Text('Biñan', style: TextStyle(fontSize: 12, color: Colors.black87))),
                              const Expanded(flex: 2, child: Text('Rice', style: TextStyle(fontSize: 12, color: Colors.black87))),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AGRICULTURAL DATA',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8),
              ),
              SizedBox(height: 4),
              Text(
                'Crop production',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0056B3)),
              ),
              SizedBox(height: 4),
              Text(
                'Municipal production estimates by crop type.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
                    const Text('Production estimates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Pagsanjan, Laguna', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Current season · Sample municipal data', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('CROP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                      Expanded(flex: 2, child: Text('ESTIMATED PRODUCTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                      Expanded(flex: 2, child: Text('AREA PLANTED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                      Expanded(flex: 2, child: Text('SEASON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                      Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                ...crops.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(Icons.eco, size: 16, color: c['color'] as Color),
                            const SizedBox(width: 8),
                            Text(c['crop'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0056B3))),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(c['production'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))),
                      Expanded(flex: 2, child: Text(c['area'] as String, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                      Expanded(flex: 2, child: Text(c['season'] as String, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c['status'] == 'Current' ? Colors.blue.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            c['status'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: c['status'] == 'Current' ? const Color(0xFF0056B3) : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Production values shown are illustrative. Replace with verified municipal records.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
  }

  Widget _buildPlaceholderView(String title, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF0056B3).withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
            const SizedBox(height: 8),
            const Text('This section is under development for the Pagsanjan Agriculture Office system.', style: TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerRow(String name, String details, String initials, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            foregroundColor: const Color(0xFF0056B3),
            child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0056B3))),
                const SizedBox(height: 1),
                Text(details, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF0056B3))),
          ),
        ],
      ),
    );
  }
}
