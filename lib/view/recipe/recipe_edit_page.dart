// New Edit Recipe Page --Vennise
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../view_models/recipe_edit_form_vm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_preview.dart';
import '../../view_models/recipe_preview.dart';

class EditRecipePage extends StatelessWidget {
  final Recipe recipe;

  const EditRecipePage({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditRecipeViewModel()..initializeWithRecipe(recipe),
      child: const _EditRecipePageBody(),
    );
  }
}

class _EditRecipePageBody extends StatefulWidget {
  const _EditRecipePageBody({Key? key}) : super(key: key);

  @override
  State<_EditRecipePageBody> createState() => _EditRecipePageBodyState();
}

class _EditRecipePageBodyState extends State<_EditRecipePageBody> {
  @override
  void dispose() {
    Provider.of<EditRecipeViewModel>(context, listen: false)
        .disposeControllers();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    final viewModel = Provider.of<EditRecipeViewModel>(context, listen: false);
    await viewModel.pickCoverImage();
  }

  void _addIngredient(BuildContext context) {
    final viewModel = Provider.of<EditRecipeViewModel>(context, listen: false);
    viewModel.showAddIngredientDialog(context);
  }

  void _addInstruction(BuildContext context) {
    final viewModel = Provider.of<EditRecipeViewModel>(context, listen: false);
    viewModel.showAddInstructionDialog(context);
  }

  Future<void> _saveRecipe(BuildContext context) async {
    final viewModel = Provider.of<EditRecipeViewModel>(context, listen: false);
    final changedFields = await viewModel.getChangedFields();

    if (changedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes to save.')),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('recipes')
          .doc(viewModel.getId());

      await docRef.update(changedFields);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recipe updated successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating recipe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditRecipeViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Edit Recipe'),
            actions: [
              IconButton(
                icon: Icon(Icons.preview),
                onPressed: () async {
                  // Go to preview page
                  final returnedViewModel = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipePreviewPage(
                          viewModel:
                              RecipePreviewViewModel(editViewModel: viewModel)),
                    ),
                  );
                  setState(() {});
                },
                tooltip: 'Preview Recipe',
              ),
              IconButton(
                icon: Icon(Icons.save),
                onPressed: () => _saveRecipe(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: viewModel.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Image
                  GestureDetector(
                    onTap: () => _pickImage(context),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: viewModel.coverImageWidget(),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Title
                  TextFormField(
                    controller: viewModel.titleController,
                    decoration: InputDecoration(labelText: 'Title'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a title' : null,
                  ),
                  SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: viewModel.descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter a description'
                        : null,
                  ),
                  SizedBox(height: 16),

                  // Servings and Time
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: viewModel.servingsController,
                          decoration: InputDecoration(labelText: 'Servings'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: viewModel.prepTimeController,
                          decoration:
                              InputDecoration(labelText: 'Prep Time (min)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: viewModel.cookTimeController,
                          decoration:
                              InputDecoration(labelText: 'Cook Time (min)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Categories
                  Text('Categories',
                      style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 8,
                    children: viewModel.availableCategories.map((category) {
                      final isSelected =
                          viewModel.selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          viewModel.toggleCategory(category, selected);
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Nutrition Info
                  Text('Nutrition Information',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                      'Now Nutrition Information will auto calculate based on ingredients',
                      style: Theme.of(context).textTheme.labelSmall),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Calories (kcal)',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Text(
                                viewModel.caloriesController.text.isEmpty
                                    ? '0'
                                    : viewModel.caloriesController.text,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Protein (g)',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Text(
                                viewModel.proteinController.text.isEmpty
                                    ? '0'
                                    : viewModel.proteinController.text,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Carbs (g)',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Text(
                                viewModel.carbsController.text.isEmpty
                                    ? '0'
                                    : viewModel.carbsController.text,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Fat (g)',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Text(
                                viewModel.fatController.text.isEmpty
                                    ? '0'
                                    : viewModel.fatController.text,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Ingredients
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ingredients',
                          style: Theme.of(context).textTheme.titleMedium),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _addIngredient(context),
                      ),
                    ],
                  ),
                  if (viewModel.ingredients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Add at least one ingredient',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: viewModel.ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = viewModel.ingredients[index];
                      return ListTile(
                        title: Text(ingredient.name),
                        subtitle:
                            Text('${ingredient.amount} ${ingredient.unit}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            viewModel.removeIngredient(index);
                          },
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),

                  // Instructions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Instructions',
                          style: Theme.of(context).textTheme.titleMedium),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => _addInstruction(context),
                      ),
                    ],
                  ),
                  if (viewModel.instructions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Add at least one instruction',
                          style: TextStyle(color: Colors.red)),
                    ),
                  if (viewModel.instructions.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: viewModel.instructions.length,
                      itemBuilder: (context, index) {
                        final instruction = viewModel.instructions[index];
                        return ListTile(
                          leading: CircleAvatar(
                              child: Text('${instruction.stepNumber}')),
                          title: Text(instruction.description),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              viewModel.removeInstruction(index);
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
