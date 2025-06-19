import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/recipe.dart'; // Import Recipe model
import '../../models/ingredient_model.dart';
import '../../models/nutrition_model.dart'; // Import NutritionInfo model with prefix
import '../../models/instruction_model.dart'; // Import Instruction model
import '../../services/caloriesninja_service.dart'; // Import CaloriesNinjaService

class RecipeFormViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final servingsController = TextEditingController();
  final prepTimeController = TextEditingController();
  final cookTimeController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final carbsController = TextEditingController();
  final fatController = TextEditingController();
  final fiberController = TextEditingController();
  final sugarController = TextEditingController();
  final CaloriesNinjaService caloriesNinjaService = CaloriesNinjaService();
  bool isLoading = false;

  XFile? coverImage;
  List<String> selectedCategories = [];
  List<Ingredient> ingredients = [];
  List<Instruction> instructions = [];
  NutritionInfo nutritionInfo = NutritionInfo(
    calories: 0,
    protein_g: 0,
    carbohydrates_total_g: 0,
    fat_total_g: 0,
    fiber_g: 0,
    sugar_g: 0,
  );
  bool isPreviewMode = false;

  final List<String> availableCategories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Snack',
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
  ];

  void initializeWithRecipe(Recipe recipe) {
    titleController.text = recipe.title;
    descriptionController.text = recipe.description;
    servingsController.text = recipe.servings.toString();
    prepTimeController.text = recipe.prepTime.toString();
    cookTimeController.text = recipe.cookTime.toString();

    selectedCategories = List<String>.from(recipe.categories);

    coverImage = XFile(recipe.coverImage);

    ingredients = recipe.ingredients;
    instructions = recipe.instructions;
    nutritionInfo = recipe.nutritionInfo;

    caloriesController.text = nutritionInfo.calories.toString();
    proteinController.text = nutritionInfo.protein_g.toString();
    carbsController.text = nutritionInfo.carbohydrates_total_g.toString();
    fatController.text = nutritionInfo.fat_total_g.toString();
    fiberController.text = nutritionInfo.fiber_g.toString();
    sugarController.text = nutritionInfo.sugar_g.toString();

    notifyListeners();
  }

  void setCoverImage(XFile? image) {
    coverImage = image;
    notifyListeners();
  }

  void addIngredient(Map<String, dynamic> ingredient) {
    ingredients.add(Ingredient.fromMap(ingredient));
    notifyListeners();
    updateNutritionInfo();
  }

  void removeIngredient(int index) {
    ingredients.removeAt(index);
    notifyListeners();
    updateNutritionInfo();
  }

  void updateNutritionInfo() async {
    // make ingredients list into a string
    final ingredientsList =
        caloriesNinjaService.convertToQueryString(ingredients);

    if (ingredientsList.isNotEmpty) {
      nutritionInfo =
          await caloriesNinjaService.fetchNutritionInfo(ingredientsList);
      caloriesController.text = nutritionInfo.calories.toString();
      proteinController.text = nutritionInfo.protein_g.toString();
      carbsController.text = nutritionInfo.carbohydrates_total_g.toString();
      fatController.text = nutritionInfo.fat_total_g.toString();
      fiberController.text = nutritionInfo.fiber_g.toString();
      sugarController.text = nutritionInfo.sugar_g.toString();
    }

    notifyListeners();
  }

  void addInstruction(Map<String, dynamic> instruction) {
    instructions.add(Instruction.fromMap(instruction));
    notifyListeners();
  }

  void removeInstruction(int index) {
    instructions.removeAt(index);
    // Update step numbers
    for (var i = 0; i < instructions.length; i++) {
      instructions[i].stepNumber = i + 1;
    }
    notifyListeners();
  }

  void toggleCategory(String category, bool selected) {
    if (selected) {
      selectedCategories.add(category);
    } else {
      selectedCategories.remove(category);
    }
    notifyListeners();
  }

  void togglePreviewMode() {
    isPreviewMode = !isPreviewMode;
    notifyListeners();
  }

  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  void disposeControllers() {
    titleController.dispose();
    descriptionController.dispose();
    servingsController.dispose();
    prepTimeController.dispose();
    cookTimeController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
  }
}
