import 'package:flutter/material.dart';
import '../models/farmer.dart';

class AccountService extends ChangeNotifier {
  final List<Farmer> _farmers = [
    Farmer(
      username: 'farmer1',
      password: 'password123',
      profileName: 'John Doe',
      records: ['Harvest Jan: 500kg', 'Harvest Feb: 450kg'],
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

  void addFarmer(String username, String password, String profileName) {
    _farmers.add(Farmer(
      username: username,
      password: password,
      profileName: profileName,
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
