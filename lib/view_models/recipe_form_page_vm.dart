import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  void updateNutritionInfo() {
    nutritionInfo = {
      'calories': double.tryParse(caloriesController.text) ?? 0,
      'protein': double.tryParse(proteinController.text) ?? 0,
      'carbs': double.tryParse(carbsController.text) ?? 0,
      'fat': double.tryParse(fatController.text) ?? 0,
    };
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
