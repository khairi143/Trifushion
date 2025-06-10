import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../view_models/recipe_form_page_vm.dart';
import '../../view_models/recipe_edit_form_vm.dart';

class RecipePreviewViewModel extends ChangeNotifier {
  final RecipeFormViewModel? formViewModel;
  final EditRecipeViewModel? editViewModel;

  RecipePreviewViewModel({
    this.formViewModel,
    this.editViewModel,
  });

  dynamic get activeViewModel => formViewModel ?? editViewModel;

  GlobalKey<FormState> get formKey => activeViewModel.formKey;
  TextEditingController get titleController => activeViewModel.titleController;
  TextEditingController get descriptionController =>
      activeViewModel.descriptionController;
  TextEditingController get servingsController =>
      activeViewModel.servingsController;
  TextEditingController get prepTimeController =>
      activeViewModel.prepTimeController;
  TextEditingController get cookTimeController =>
      activeViewModel.cookTimeController;
  TextEditingController get caloriesController =>
      activeViewModel.caloriesController;
  TextEditingController get proteinController =>
      activeViewModel.proteinController;
  TextEditingController get carbsController => activeViewModel.carbsController;
  TextEditingController get fatController => activeViewModel.fatController;
  XFile? get coverImage => activeViewModel.coverImage;
  List<String> get selectedCategories => activeViewModel.selectedCategories;
  List<Map<String, dynamic>> get ingredients => activeViewModel.ingredients;
  List<Map<String, dynamic>> get instructions => activeViewModel.instructions;
  Map<String, dynamic> get nutritionInfo => activeViewModel.nutritionInfo;
}
