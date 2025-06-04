import 'package:flutter/material.dart';
import '../../view_models/recipe_form_page_vm.dart';

class RecipePreviewViewModel extends ChangeNotifier {
  final RecipeFormViewModel formViewModel;

  RecipePreviewViewModel(this.formViewModel);

  // Add any preview-specific logic here if needed
}
