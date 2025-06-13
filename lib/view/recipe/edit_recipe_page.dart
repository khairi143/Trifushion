import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../../models/ingredient_model.dart' as ingredient_model;
import '../../models/nutrition_model.dart' as nutrition_model;
import '../../models/instruction_model.dart' as instruction_model;

class EditRecipePage extends StatefulWidget {
  final Recipe recipe;

  EditRecipePage({Key? key, required this.recipe}) : super(key: key);

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final RecipeService _recipeService = RecipeService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _servingsController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;

  XFile? _newCoverImage;

  // Track selected categories
  List<String> _categories = [];
  final List<String> _availableCategories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert'
  ];

  // Track nutrition information
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  // Ingredients management controllers
  late TextEditingController _ingredientNameController;
  late TextEditingController _ingredientAmountController;
  late TextEditingController _ingredientUnitController;

  List<ingredient_model.Ingredient> _ingredients =
      []; // Keep the updated list of ingredients
  int?
      _editingIngredientIndex; // Track the index of the ingredient being edited

  // Instructions management controllers
  late TextEditingController _instructionStepController;
  late TextEditingController _instructionDescriptionController;

  List<instruction_model.Instruction> _instructions =
      []; // Keep the updated list of instructions
  int?
      _editingInstructionIndex; // Track the index of the instruction being edited

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController =
        TextEditingController(text: widget.recipe.description);
    _servingsController =
        TextEditingController(text: widget.recipe.servings.toString());
    _prepTimeController =
        TextEditingController(text: widget.recipe.prepTime.toString());
    _cookTimeController =
        TextEditingController(text: widget.recipe.cookTime.toString());

    _categories = List<String>.from(widget.recipe.categories);

    _caloriesController = TextEditingController(
        text: widget.recipe.nutritionInfo.calories.toString());
    _proteinController = TextEditingController(
        text: widget.recipe.nutritionInfo.protein_g.toString());
    _carbsController = TextEditingController(
        text: widget.recipe.nutritionInfo.carbohydrates_total_g.toString());
    _fatController = TextEditingController(
        text: widget.recipe.nutritionInfo.fat_total_g.toString());

    _ingredients =
        List<ingredient_model.Ingredient>.from(widget.recipe.ingredients);

    _instructions =
        List<instruction_model.Instruction>.from(widget.recipe.instructions);

    _ingredientNameController = TextEditingController();
    _ingredientAmountController = TextEditingController();
    _ingredientUnitController = TextEditingController();

    _instructionStepController = TextEditingController();
    _instructionDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _ingredientNameController.dispose();
    _ingredientAmountController.dispose();
    _ingredientUnitController.dispose();
    _instructionStepController.dispose();
    _instructionDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newCoverImage = image;
      });
    }
  }

  // Show Dialog to Add or Update Ingredient
  void _showIngredientDialog(int? editingIndex) {
    if (editingIndex != null) {
      // Populate with the existing ingredient data
      _ingredientNameController.text = _ingredients[editingIndex].name;
      _ingredientAmountController.text =
          _ingredients[editingIndex].amount.toString();
      _ingredientUnitController.text = _ingredients[editingIndex].unit;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(editingIndex != null ? 'Edit Ingredient' : 'Add Ingredient'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _ingredientNameController,
                  decoration: InputDecoration(labelText: 'Ingredient Name'),
                ),
                TextField(
                  controller: _ingredientAmountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _ingredientUnitController,
                  decoration: InputDecoration(labelText: 'Unit'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Add or Update Ingredient
                final name = _ingredientNameController.text;
                final amount =
                    double.tryParse(_ingredientAmountController.text) ?? 0.0;
                final unit = _ingredientUnitController.text;

                final newIngredient = ingredient_model.Ingredient(
                  name: name,
                  amount: amount,
                  unit: unit,
                );

                setState(() {
                  if (editingIndex != null) {
                    _ingredients[editingIndex] = newIngredient;
                  } else {
                    _ingredients.add(newIngredient);
                  }
                });

                _ingredientNameController.clear();
                _ingredientAmountController.clear();
                _ingredientUnitController.clear();

                Navigator.of(context).pop();
              },
              child: Text(editingIndex != null
                  ? 'Update Ingredient'
                  : 'Add Ingredient'),
            ),
          ],
        );
      },
    );
  }

  // Show Dialog to Add or Update Instruction
  void _showInstructionDialog(int? editingIndex) {
    if (editingIndex != null) {
      // Populate with the existing instruction data
      _instructionStepController.text =
          _instructions[editingIndex].stepNumber.toString();
      _instructionDescriptionController.text =
          _instructions[editingIndex].description;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              editingIndex != null ? 'Edit Instruction' : 'Add Instruction'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _instructionStepController,
                  decoration: InputDecoration(labelText: 'Step Number'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _instructionDescriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final stepNumber =
                    int.tryParse(_instructionStepController.text) ?? 0;
                final description = _instructionDescriptionController.text;

                final newInstruction = instruction_model.Instruction(
                  stepNumber: stepNumber,
                  description: description,
                  videoUrl: null,
                  localVideoPath: null,
                  duration: null,
                );

                setState(() {
                  if (editingIndex != null) {
                    _instructions[editingIndex] = newInstruction;
                  } else {
                    _instructions.add(newInstruction);
                  }
                });

                _instructionStepController.clear();
                _instructionDescriptionController.clear();

                Navigator.of(context).pop();
              },
              child: Text(editingIndex != null
                  ? 'Update Instruction'
                  : 'Add Instruction'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Convert nutrition info
        Map<String, dynamic> updatedNutritionInfo = {
          'calories': double.tryParse(_caloriesController.text) ?? 0.0,
          'protein': double.tryParse(_proteinController.text) ?? 0.0,
          'carbs': double.tryParse(_carbsController.text) ?? 0.0,
          'fat': double.tryParse(_fatController.text) ?? 0.0,
        };

        Recipe updatedRecipe = Recipe(
          id: widget.recipe.id,
          title: _titleController.text,
          coverImage: widget.recipe.coverImage,
          servings: int.parse(_servingsController.text),
          prepTime: int.parse(_prepTimeController.text),
          cookTime: int.parse(_cookTimeController.text),
          totalTime: (int.parse(_prepTimeController.text) +
              int.parse(_cookTimeController.text)),
          description: _descriptionController.text,
          categories: _categories,
          ingredients: _ingredients,
          instructions: _instructions,
          nutritionInfo:
              nutrition_model.NutritionInfo.fromMap(updatedNutritionInfo),
          userId: widget.recipe.userId,
          createdAt: widget.recipe.createdAt,
          updatedAt: DateTime.now(),
          createdByName: widget.recipe.createdByName,
        );

        if (_newCoverImage != null) {
          String newCoverImageUrl = await _recipeService
              .uploadImageToStorage(File(_newCoverImage!.path));
          updatedRecipe = updatedRecipe.copyWith(coverImage: newCoverImageUrl);
        }

        await _recipeService.updateRecipe(widget.recipe.id, updatedRecipe);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recipe updated successfully!')));

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error updating recipe: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Recipe'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ),
              SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ),
              SizedBox(height: 16),

              // Servings
              TextFormField(
                controller: _servingsController,
                decoration: InputDecoration(labelText: 'Servings'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter servings' : null,
              ),
              SizedBox(height: 16),

              // Prep Time
              TextFormField(
                controller: _prepTimeController,
                decoration: InputDecoration(labelText: 'Prep Time (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter prep time' : null,
              ),
              SizedBox(height: 16),

              // Cook Time
              TextFormField(
                controller: _cookTimeController,
                decoration: InputDecoration(labelText: 'Cook Time (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter cook time' : null,
              ),
              SizedBox(height: 16),

              // categories section
              Text('Categories',
                  style: Theme.of(context).textTheme.titleMedium),
              Column(
                children: _availableCategories.map((category) {
                  return CheckboxListTile(
                    title: Text(category),
                    value: _categories.contains(category),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected != null) {
                          if (selected) {
                            _categories.add(category);
                          } else {
                            _categories.remove(category);
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // ingredients section
              Text('Ingredients',
                  style: Theme.of(context).textTheme.titleMedium),
              Column(
                children: _ingredients.map((ingredient) {
                  return ListTile(
                    title: Text(ingredient.name),
                    subtitle:
                        Text('Amount: ${ingredient.amount} ${ingredient.unit}'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showIngredientDialog(_ingredients.indexOf(ingredient));
                      },
                    ),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: () {
                  _showIngredientDialog(null);
                },
                child: Text('Add or Update Ingredient'),
              ),
              SizedBox(height: 16),

              // instructions section
              Text('Instructions',
                  style: Theme.of(context).textTheme.titleMedium),
              Column(
                children: _instructions.map((instruction) {
                  return ListTile(
                    title: Text(
                        'Step ${instruction?.stepNumber ?? ''}: ${instruction?.description ?? ''}'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showInstructionDialog(
                            _instructions.indexOf(instruction));
                      },
                    ),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: () {
                  _showInstructionDialog(null);
                },
                child: Text('Add or Update Instruction'),
              ),
              SizedBox(height: 16),

              //image section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _newCoverImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_newCoverImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : widget.recipe.coverImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.recipe.coverImage,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.add_photo_alternate, size: 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
