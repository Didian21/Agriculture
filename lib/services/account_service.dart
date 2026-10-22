import 'package:flutter/material.dart';
import '../models/farmer.dart';

class AccountService extends ChangeNotifier {
  final List<Farmer> _farmers = [
    Farmer(
      username: 'farmer1',
      password: 'password123',
      profileName: 'Juan Dela Cruz',
      landSize: '2.5 ha',
      cropPlanted: 'Rice',
      location: 'Biñan',
      contactNumber: '09123456789',
      records: ['Harvest Q1: 1,200kg', 'Fertilizer Subsidy Received'],
    ),
    Farmer(
      username: 'farmer2',
      password: 'password123',
      profileName: 'Maria Santos',
      landSize: '1.8 ha',
      cropPlanted: 'Coconut',
      location: 'Lambac',
      contactNumber: '09198765432',
      records: ['Harvest Q1: 950kg'],
    ),
    Farmer(
      username: 'farmer3',
      password: 'password123',
      profileName: 'Pedro Reyes',
      landSize: '3.0 ha',
      cropPlanted: 'Banana',
      location: 'Buboy',
      contactNumber: '09181112233',
      records: ['Seed distribution registered'],
    ),
  ];

  final List<Map<String, String>> _posts = [
    {
      'title': 'Typhoon Advisory for Farmers',
      'content': 'Please harvest mature crops early due to expected weather disturbance next week.',
      'date': 'Oct 24, 2026',
    },
    {
      'title': 'Subsidized Fertilizer Distribution',
      'content': 'Free organic fertilizer claiming is now open at the Municipal Agriculture Office.',
      'date': 'Oct 22, 2026',
    },
  ];

  List<Farmer> get farmers => List.unmodifiable(_farmers);
  List<Map<String, String>> get posts => List.unmodifiable(_posts);

  void addFarmer({
    required String username,
    required String password,
    required String profileName,
    String landSize = '1.0 ha',
    String cropPlanted = 'Rice',
    String location = 'Pagsanjan',
    String contactNumber = '09123456789',
  }) {
    _farmers.add(Farmer(
      username: username,
      password: password,
      profileName: profileName,
      landSize: landSize,
      cropPlanted: cropPlanted,
      location: location,
      contactNumber: contactNumber,
    ));
    notifyListeners();
  }

  void addPost(String title, String content) {
    _posts.insert(0, {
      'title': title,
      'content': content,
      'date': 'Today',
    });
    notifyListeners();
  }

  Farmer? authenticateFarmer(String username, String password) {
    try {
      return _farmers.firstWhere(
        (f) => f.username == username && f.password == password,
      );
    } catch (e) {
      return null;
    }
  }

  bool authenticateAdmin(String username, String password) {
    return username == 'admin' && password == 'admin123';
  }
}
