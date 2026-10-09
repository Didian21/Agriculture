import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/farmer.dart';
import '../services/account_service.dart';
import '../services/prediction_service.dart';

class FarmerDashboard extends StatelessWidget {
  final Farmer farmer;
  const FarmerDashboard({super.key, required this.farmer});

  void _showPrediction(BuildContext context) {
    final prediction = PredictionService.getProductionPrediction();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Production Prediction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${prediction['mlStatus']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Historical: ${prediction['historicalData']}'),
            Text('Weather: ${prediction['weatherEffect']}'),
            const SizedBox(height: 10),
            Text('Estimated Yield: ${prediction['productionEstimate']}', style: const TextStyle(color: Colors.green, fontSize: 18)),
            Text('Predicted Price: ${prediction['pricePrediction']}', style: const TextStyle(color: Colors.blue, fontSize: 18)),
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset('Pagri.jpg', width: 28, height: 28, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Text('Farmer Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          )
        ],
      ),
      body: Consumer<AccountService>(
        builder: (context, accountService, child) {
          final posts = accountService.posts;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.green.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.account_circle, size: 50, color: Colors.green),
                    title: Text(farmer.profileName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Verified Farmer'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Office Announcements & Advisories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0056B3))),
                const SizedBox(height: 10),
                if (posts.isEmpty)
                  const Text('No announcements yet.', style: TextStyle(color: Colors.grey))
                else
                  ...posts.map((post) => Card(
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
                const Text('Agricultural Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A3B2B))),
                const SizedBox(height: 10),
                ...farmer.records.map((record) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment, color: Colors.green),
                    title: Text(record),
                  ),
                )),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPrediction(context),
                    icon: const Icon(Icons.analytics, color: Colors.white),
                    label: const Text('View Production Prediction', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
