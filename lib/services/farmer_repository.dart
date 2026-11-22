import 'package:flutter/material.dart';

import '../models/farm_models.dart';
import '../models/planting_guide.dart';

class FarmerRepository {
  Future<FarmerProfile> getProfile() async => const FarmerProfile(
    name: 'Wency Babaan',
    barangay: 'Barangay Sampaloc',
    landSizeHectares: 2.5,
    cropTypes: ['Rice', 'Eggplant', 'Tomato'],
  );

  Future<List<FarmPlot>> getPlots() async => const [
    FarmPlot(crop: 'Rice', hectares: 1.2, status: PlotStatus.harvested),
    FarmPlot(crop: 'Eggplant', hectares: 0.7, status: PlotStatus.harvested),
    FarmPlot(crop: 'Tomato', hectares: 0.6, status: PlotStatus.growing),
  ];

  Future<List<CropRecord>> getCropHistory() async => [
    CropRecord(crop: 'Rice', datePlanted: DateTime(2025, 6, 10), dateHarvested: DateTime(2025, 10, 5), yieldKg: 5200),
    CropRecord(crop: 'Eggplant', datePlanted: DateTime(2025, 11, 2), dateHarvested: DateTime(2026, 1, 20), yieldKg: 1800),
    CropRecord(crop: 'Tomato', datePlanted: DateTime(2026, 8, 15), yieldKg: 0),
  ];

  /// Kalendaryo ng pagtatanim para sa Pagsanjan, Laguna.
  /// Ang pagkakasunod-sunod dito ang pagkakasunod sa Home.
  List<PlantingGuide> getPlantingGuides() => const [
    PlantingGuide(
      crop: 'Banana',
      icon: Icons.park,
      color: Color(0xFFE6A700),
      image: 'assets/images/crops/banana.jpg',
      bestMonths: {5, 6, 7},
      possibleMonths: {4, 8, 9},
    ),
    PlantingGuide(
      crop: 'Rice',
      icon: Icons.grass,
      color: Color(0xFFC0A02B),
      image: 'assets/images/crops/rice.jpg',
      bestMonths: {6, 7, 11, 12},
      possibleMonths: {5, 8, 1},
    ),
    // TANTIYA - ipakumpirma sa Agri Office
    PlantingGuide(
      crop: 'Coconut',
      icon: Icons.park,
      color: Color(0xFF8D6E63),
      image: 'assets/images/crops/coconut.jpg',
      bestMonths: {6, 7, 8},
      possibleMonths: {5, 9},
    ),
    PlantingGuide(
      crop: 'Eggplant',
      icon: Icons.eco,
      color: Color(0xFF7B4FA3),
      image: 'assets/images/crops/eggplant.jpg',
      bestMonths: {10, 11, 12, 1},
      possibleMonths: {2, 9},
    ),
    // TANTIYA - ipakumpirma sa Agri Office
    PlantingGuide(
      crop: 'Ampalaya',
      icon: Icons.eco,
      color: Color(0xFF3B8F3B),
      image: 'assets/images/crops/ampalaya.jpg',
      bestMonths: {10, 11, 12, 1},
      possibleMonths: {2, 3, 9},
    ),
    PlantingGuide(
      crop: 'String beans',
      icon: Icons.spa,
      color: Color(0xFF2E9E5B),
      image: 'assets/images/crops/string_beans.jpg',
      bestMonths: {10, 11, 12, 1},
      possibleMonths: {2, 4, 5, 9},
    ),
    // TANTIYA - ipakumpirma sa Agri Office
    PlantingGuide(
      crop: 'Squash',
      icon: Icons.spa,
      color: Color(0xFFE08A1E),
      image: 'assets/images/crops/squash.jpg',
      bestMonths: {10, 11, 12},
      possibleMonths: {1, 5, 6, 9},
    ),
    PlantingGuide(
      crop: 'Tomato',
      icon: Icons.local_florist,
      color: Color(0xFFE5533D),
      image: 'assets/images/crops/tomato.jpg',
      bestMonths: {10, 11, 12},
      possibleMonths: {1, 2, 9},
    ),
    // TANTIYA - ipakumpirma sa Agri Office
    PlantingGuide(
      crop: 'Sweet potato',
      icon: Icons.grass,
      color: Color(0xFF9C5A9E),
      image: 'assets/images/crops/sweet_potato.jpg',
      bestMonths: {5, 6, 10, 11},
      possibleMonths: {7, 9, 12, 1},
    ),
    // TANTIYA - ipakumpirma sa Agri Office
    PlantingGuide(
      crop: 'Taro',
      icon: Icons.eco,
      color: Color(0xFF5E8C61),
      image: 'assets/images/crops/taro.jpg',
      bestMonths: {5, 6, 7},
      possibleMonths: {4, 8, 9, 10},
    ),
    // TANTIYA - ipakumpirma sa Agri Office
    PlantingGuide(
      crop: 'Calamansi',
      icon: Icons.spa,
      color: Color(0xFF8BC34A),
      image: 'assets/images/crops/calamansi.jpg',
      bestMonths: {6, 7, 8},
      possibleMonths: {5, 9, 10},
    ),
  ];
}