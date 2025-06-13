import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/nutrition_model.dart';
import '../../models/ingredient_model.dart';

class CaloriesNinjaService extends ChangeNotifier {
  final String apiKey = 'SFUKEdSU/WadeFoFYXQ+lA==nKoasoMp22uPgrFw';

  Future<NutritionInfo> fetchNutritionInfo(String query) async {
    final url =
        Uri.parse('https://api.calorieninjas.com/v1/nutrition?query=$query');

    final response = await http.get(url, headers: {'X-Api-Key': apiKey});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>;

      double calories = 0;
      double proteinG = 0;
      double carbohydratesTotalG = 0;
      double fatTotalG = 0;
      double fiberG = 0;
      double sugarG = 0;

      // Sum up nutrition info from all the items
      for (var item in items) {
        if (item is Map<String, dynamic>) {
          final nutrition = NutritionInfo.fromMap(item);
          calories += nutrition.calories;
          proteinG += nutrition.protein_g;
          carbohydratesTotalG += nutrition.carbohydrates_total_g;
          fatTotalG += nutrition.fat_total_g;
          fiberG += nutrition.fiber_g;
          sugarG += nutrition.sugar_g;
        }
      }

      // Create a new NutritionInfo object with summed values
      return NutritionInfo(
        calories: calories,
        protein_g: proteinG,
        carbohydrates_total_g: carbohydratesTotalG,
        fat_total_g: fatTotalG,
        fiber_g: fiberG,
        sugar_g: sugarG,
      );
    } else if (response.statusCode == 404) {
      // If no items found, return empty NutritionInfo
      return NutritionInfo(
        calories: 0,
        protein_g: 0,
        carbohydrates_total_g: 0,
        fat_total_g: 0,
        fiber_g: 0,
        sugar_g: 0,
      );
    } else {
      throw Exception('Failed to fetch nutrition info');
    }
  }

  String convertToQueryString(List<Ingredient> ingredients) {
    return ingredients
        .map((ingredient) => ingredient.toQueryString())
        .join(', ');
  }
}
