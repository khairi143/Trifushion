class NutritionInfo {
  final double calories;
  final double protein_g;
  final double carbohydrates_total_g;
  final double fat_total_g;
  final double fiber_g;
  final double sugar_g;

  NutritionInfo({
    required this.calories,
    required this.protein_g,
    required this.carbohydrates_total_g,
    required this.fat_total_g,
    required this.fiber_g,
    required this.sugar_g,
  });

  factory NutritionInfo.fromMap(Map<String, dynamic> map) {
    return NutritionInfo(
      calories: (map['calories'] ?? 0.0).toDouble(),
      protein_g: (map['protein_g'] ?? 0.0).toDouble(),
      carbohydrates_total_g: (map['carbohydrates_total_g'] ?? 0.0).toDouble(),
      fat_total_g: (map['fat_total_g'] ?? 0.0).toDouble(),
      fiber_g: (map['fiber_g'] ?? 0.0).toDouble(),
      sugar_g: (map['sugar_g'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein_g': protein_g,
      'carbohydrates_total_g': carbohydrates_total_g,
      'fat_total_g': fat_total_g,
      'fiber_g': fiber_g,
      'sugar_g': sugar_g,
    };
  }
}
