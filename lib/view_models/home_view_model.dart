import 'package:flutter/material.dart';
import 'dart:async';

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final double rating;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.rating,
  });
}

class HomeViewModel extends ChangeNotifier {
  List<Recipe> _dailyInspiration = [];
  List<Recipe> _latestRecipes = [];
  List<Recipe> _recentlyViewed = [];
  List<Recipe> _popularRecipes = [];
  int _currentInspirationIndex = 0;
  Timer? _slideshowTimer;

  List<Recipe> get dailyInspiration => _dailyInspiration;
  List<Recipe> get latestRecipes => _latestRecipes;
  List<Recipe> get recentlyViewed => _recentlyViewed;
  List<Recipe> get popularRecipes => _popularRecipes;
  int get currentInspirationIndex => _currentInspirationIndex;

  void setCurrentInspirationIndex(int index) {
    _currentInspirationIndex = index;
    notifyListeners();
  }

  void startSlideshow() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_dailyInspiration.isNotEmpty) {
        _currentInspirationIndex = (_currentInspirationIndex + 1) % _dailyInspiration.length;
        notifyListeners();
      }
    });
  }

  void stopSlideshow() {
    _slideshowTimer?.cancel();
    _slideshowTimer = null;
  }

  @override
  void dispose() {
    stopSlideshow();
    super.dispose();
  }

  Future<void> loadDailyInspiration() async {
    // TODO: Implement API call to fetch daily inspiration
    _dailyInspiration = [
      Recipe(
        id: '1',
        title: 'Healthy Mediterranean Bowl',
        imageUrl: 'images/mediterranean_bowl.jpg',
        description: 'A nutritious bowl packed with fresh vegetables and lean protein',
        rating: 4.8,
      ),
      Recipe(
        id: '2',
        title: 'Quinoa Buddha Bowl',
        imageUrl: 'images/quinoa_bowl.jpg',
        description: 'Protein-rich quinoa bowl with roasted vegetables',
        rating: 4.6,
      ),
      Recipe(
        id: '3',
        title: 'Avocado Toast',
        imageUrl: 'images/avocado_toast.jpg',
        description: 'Simple and delicious avocado toast with microgreens',
        rating: 4.5,
      ),
    ];
    notifyListeners();
  }

  Future<void> loadLatestRecipes() async {
    // TODO: Implement API call to fetch latest recipes
    _latestRecipes = [
      Recipe(
        id: '4',
        title: 'Green Smoothie Bowl',
        imageUrl: 'images/smoothie_bowl.jpg',
        description: 'Energizing green smoothie bowl with fresh fruits',
        rating: 4.9,
      ),
      Recipe(
        id: '5',
        title: 'Vegan Poke Bowl',
        imageUrl: 'images/poke_bowl.jpg',
        description: 'Fresh and colorful vegan poke bowl',
        rating: 4.7,
      ),
    ];
    notifyListeners();
  }

  Future<void> loadRecentlyViewed() async {
    // TODO: Implement local storage fetch for recently viewed recipes
    _recentlyViewed = [
      Recipe(
        id: '6',
        title: 'Chicken Salad',
        imageUrl: 'images/chicken_salad.jpg',
        description: 'Healthy chicken salad with mixed greens',
        rating: 4.4,
      ),
      Recipe(
        id: '7',
        title: 'Fruit Parfait',
        imageUrl: 'images/fruit_parfait.jpg',
        description: 'Layered fruit parfait with yogurt and granola',
        rating: 4.6,
      ),
    ];
    notifyListeners();
  }

  Future<void> loadPopularRecipes() async {
    // TODO: Implement API call to fetch popular recipes
    _popularRecipes = [
      Recipe(
        id: '8',
        title: 'Vegetable Stir Fry',
        imageUrl: 'images/stir_fry.jpg',
        description: 'Quick and healthy vegetable stir fry',
        rating: 4.8,
      ),
      Recipe(
        id: '9',
        title: 'Greek Salad',
        imageUrl: 'images/greek_salad.jpg',
        description: 'Classic Greek salad with feta cheese',
        rating: 4.7,
      ),
    ];
    notifyListeners();
  }

  Future<void> initialize() async {
    await Future.wait([
      loadDailyInspiration(),
      loadLatestRecipes(),
      loadRecentlyViewed(),
      loadPopularRecipes(),
    ]);
    startSlideshow();
  }
} 