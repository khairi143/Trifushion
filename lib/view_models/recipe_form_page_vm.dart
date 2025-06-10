import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/recipe.dart'; // Import Recipe model

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

  XFile? coverImage;
  List<String> selectedCategories = [];
  List<Map<String, dynamic>> ingredients = [];
  List<Map<String, dynamic>> instructions = [];
  Map<String, dynamic> nutritionInfo = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
  };
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

    ingredients = List<Map<String, dynamic>>.from(recipe.ingredients);
    instructions = List<Map<String, dynamic>>.from(recipe.instructions);

    nutritionInfo = {
      'calories': recipe.nutritionInfo.calories,
      'protein': recipe.nutritionInfo.protein,
      'carbs': recipe.nutritionInfo.carbs,
      'fat': recipe.nutritionInfo.fat,
    };

    caloriesController.text = nutritionInfo['calories'].toString();
    proteinController.text = nutritionInfo['protein'].toString();
    carbsController.text = nutritionInfo['carbs'].toString();
    fatController.text = nutritionInfo['fat'].toString();

    notifyListeners();
  }

  void setCoverImage(XFile? image) {
    coverImage = image;
    notifyListeners();
  }

  void addIngredient(Map<String, dynamic> ingredient) {
    ingredients.add(ingredient);
    notifyListeners();
  }

  void removeIngredient(int index) {
    ingredients.removeAt(index);
    notifyListeners();
  }

  void addInstruction(Map<String, dynamic> instruction) {
    instructions.add(instruction);
    notifyListeners();
  }

  void removeInstruction(int index) {
    instructions.removeAt(index);
    // Update step numbers
    for (var i = 0; i < instructions.length; i++) {
      instructions[i]['step'] = i + 1;
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
