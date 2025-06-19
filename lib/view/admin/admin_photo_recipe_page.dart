import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/recipe.dart';
import '../../models/ingredient_model.dart';
import '../../models/instruction_model.dart';
import '../../models/nutrition_model.dart';
import '../../services/recipe_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPhotoRecipePage extends StatefulWidget {
  const AdminPhotoRecipePage({Key? key}) : super(key: key);

  @override
  _AdminPhotoRecipePageState createState() => _AdminPhotoRecipePageState();
}

class _AdminPhotoRecipePageState extends State<AdminPhotoRecipePage> {
  final ImagePicker _imagePicker = ImagePicker();
  final RecipeService _recipeService = RecipeService();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final TextEditingController _cookTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  
  List<Ingredient> _ingredients = [];
  List<Instruction> _instructions = [];
  List<String> _selectedCategories = [];
  NutritionInfo _nutritionInfo = NutritionInfo(
    calories: 0.0,
    protein_g: 0.0,
    carbohydrates_total_g: 0.0,
    fat_total_g: 0.0,
    fiber_g: 0.0,
    sugar_g: 0.0,
  );
  XFile? _selectedImage;
  XFile? _coverImage;
  bool _isProcessing = false;
  
  final List<String> _availableCategories = [
    'Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack',
    'Vegetarian', 'Vegan', 'Gluten-Free', 'Quick & Easy'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _pickImageForOcr() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _isProcessing = true;
      });
      
      // Simulate OCR processing
      await Future.delayed(Duration(seconds: 2));
      
      setState(() {
        _titleController.text = 'Recipe from Photo';
        _descriptionController.text = 'This recipe was extracted from a photo.';
        _ingredients = [
          Ingredient(name: 'Ingredient 1', amount: 1.0, unit: 'cup'),
          Ingredient(name: 'Ingredient 2', amount: 2.0, unit: 'tbsp'),
          Ingredient(name: 'Ingredient 3', amount: 0.5, unit: 'tsp'),
        ];
        _instructions = [
          Instruction(stepNumber: 1, description: 'Prepare ingredients', videoUrl: ''),
          Instruction(stepNumber: 2, description: 'Cook the ingredients', videoUrl: ''),
          Instruction(stepNumber: 3, description: 'Serve and enjoy', videoUrl: ''),
        ];
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe extracted! Found ${_ingredients.length} ingredients and ${_instructions.length} instructions.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
        _isProcessing = true;
      });
      
      // Simulate OCR processing
      await Future.delayed(Duration(seconds: 2));
      
      setState(() {
        _titleController.text = 'Recipe from Photo';
        _descriptionController.text = 'This recipe was extracted from a photo.';
        _ingredients = [
          Ingredient(name: 'Ingredient 1', amount: 1.0, unit: 'cup'),
          Ingredient(name: 'Ingredient 2', amount: 2.0, unit: 'tbsp'),
          Ingredient(name: 'Ingredient 3', amount: 0.5, unit: 'tsp'),
        ];
        _instructions = [
          Instruction(stepNumber: 1, description: 'Prepare ingredients', videoUrl: ''),
          Instruction(stepNumber: 2, description: 'Cook the ingredients', videoUrl: ''),
          Instruction(stepNumber: 3, description: 'Serve and enjoy', videoUrl: ''),
        ];
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe extracted! Found ${_ingredients.length} ingredients and ${_instructions.length} instructions.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _coverImage = pickedFile;
      });
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(Ingredient(name: 'New ingredient', amount: 1.0, unit: 'cup'));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addInstruction() {
    setState(() {
      _instructions.add(Instruction(stepNumber: _instructions.length + 1, description: 'New instruction', videoUrl: ''));
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
      // Update step numbers
      for (int i = 0; i < _instructions.length; i++) {
        _instructions[i] = Instruction(
          stepNumber: i + 1,
          description: _instructions[i].description,
          videoUrl: _instructions[i].videoUrl,
        );
      }
    });
  }

  Future<void> _saveRecipe() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe title')),
      );
      return;
    }

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    if (_instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one instruction')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get current admin user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Create Recipe object
      final recipe = Recipe(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        coverImage: '', // Will be set by the service if cover image exists
        servings: int.tryParse(_servingsController.text) ?? 1,
        prepTime: int.tryParse(_prepTimeController.text) ?? 0,
        cookTime: int.tryParse(_cookTimeController.text) ?? 0,
        totalTime: (int.tryParse(_prepTimeController.text) ?? 0) + (int.tryParse(_cookTimeController.text) ?? 0),
        categories: _selectedCategories,
        ingredients: _ingredients,
        instructions: _instructions,
        nutritionInfo: _nutritionInfo,
        userId: currentUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdByName: currentUser.displayName ?? 'Admin',
      );

      // Save to Firestore with cover image
      final recipeId = await _recipeService.createRecipe(
        recipe, 
        _coverImage != null ? File(_coverImage!.path) : null
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe saved successfully! ID: $recipeId'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _clearForm();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving recipe: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _prepTimeController.clear();
      _cookTimeController.clear();
      _servingsController.clear();
      _ingredients.clear();
      _instructions.clear();
      _selectedCategories.clear();
      _selectedImage = null;
      _coverImage = null;
      _nutritionInfo = NutritionInfo(
        calories: 0.0,
        protein_g: 0.0,
        carbohydrates_total_g: 0.0,
        fat_total_g: 0.0,
        fiber_g: 0.0,
        sugar_g: 0.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Recipe from Photo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo Upload Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extract Recipe from Photo',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageForOcr,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('From Gallery'),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImage!.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                    if (_isProcessing)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recipe Details Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recipe Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Recipe Title *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _prepTimeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Prep Time (min)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _cookTimeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cook Time (min)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _servingsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Servings',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cover Image Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cover Image',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickCoverImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Select Cover Image'),
                    ),
                    if (_coverImage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_coverImage!.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Categories
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _availableCategories.map((category) {
                        final isSelected = _selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Nutrition Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        TextFormField(
                          initialValue: _nutritionInfo.calories.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _nutritionInfo = NutritionInfo(
                                calories: double.tryParse(value) ?? _nutritionInfo.calories,
                                protein_g: _nutritionInfo.protein_g,
                                carbohydrates_total_g: _nutritionInfo.carbohydrates_total_g,
                                fat_total_g: _nutritionInfo.fat_total_g,
                                fiber_g: _nutritionInfo.fiber_g,
                                sugar_g: _nutritionInfo.sugar_g,
                              );
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Calories',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: _nutritionInfo.protein_g.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _nutritionInfo = NutritionInfo(
                                calories: _nutritionInfo.calories,
                                protein_g: double.tryParse(value) ?? _nutritionInfo.protein_g,
                                carbohydrates_total_g: _nutritionInfo.carbohydrates_total_g,
                                fat_total_g: _nutritionInfo.fat_total_g,
                                fiber_g: _nutritionInfo.fiber_g,
                                sugar_g: _nutritionInfo.sugar_g,
                              );
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Protein (g)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: _nutritionInfo.carbohydrates_total_g.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _nutritionInfo = NutritionInfo(
                                calories: _nutritionInfo.calories,
                                protein_g: _nutritionInfo.protein_g,
                                carbohydrates_total_g: double.tryParse(value) ?? _nutritionInfo.carbohydrates_total_g,
                                fat_total_g: _nutritionInfo.fat_total_g,
                                fiber_g: _nutritionInfo.fiber_g,
                                sugar_g: _nutritionInfo.sugar_g,
                              );
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Carbs (g)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: _nutritionInfo.fat_total_g.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _nutritionInfo = NutritionInfo(
                                calories: _nutritionInfo.calories,
                                protein_g: _nutritionInfo.protein_g,
                                carbohydrates_total_g: _nutritionInfo.carbohydrates_total_g,
                                fat_total_g: double.tryParse(value) ?? _nutritionInfo.fat_total_g,
                                fiber_g: _nutritionInfo.fiber_g,
                                sugar_g: _nutritionInfo.sugar_g,
                              );
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Fat (g)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: _nutritionInfo.fiber_g.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _nutritionInfo = NutritionInfo(
                                calories: _nutritionInfo.calories,
                                protein_g: _nutritionInfo.protein_g,
                                carbohydrates_total_g: _nutritionInfo.carbohydrates_total_g,
                                fat_total_g: _nutritionInfo.fat_total_g,
                                fiber_g: double.tryParse(value) ?? _nutritionInfo.fiber_g,
                                sugar_g: _nutritionInfo.sugar_g,
                              );
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Fiber (g)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextFormField(
                          initialValue: _nutritionInfo.sugar_g.toString(),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _nutritionInfo = NutritionInfo(
                                calories: _nutritionInfo.calories,
                                protein_g: _nutritionInfo.protein_g,
                                carbohydrates_total_g: _nutritionInfo.carbohydrates_total_g,
                                fat_total_g: _nutritionInfo.fat_total_g,
                                fiber_g: _nutritionInfo.fiber_g,
                                sugar_g: double.tryParse(value) ?? _nutritionInfo.sugar_g,
                              );
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Sugar (g)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ingredients Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ingredients',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          onPressed: _addIngredient,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: ingredient.name,
                                  onChanged: (value) {
                                    setState(() {
                                      _ingredients[index] = Ingredient(
                                        name: value,
                                        amount: ingredient.amount,
                                        unit: ingredient.unit,
                                      );
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Ingredient ${index + 1}',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: ingredient.amount.toString(),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _ingredients[index] = Ingredient(
                                        name: ingredient.name,
                                        amount: double.tryParse(value) ?? ingredient.amount,
                                        unit: ingredient.unit,
                                      );
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Amount',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: ingredient.unit,
                                  onChanged: (value) {
                                    setState(() {
                                      _ingredients[index] = Ingredient(
                                        name: ingredient.name,
                                        amount: ingredient.amount,
                                        unit: value,
                                      );
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeIngredient(index),
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Instructions',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          onPressed: _addInstruction,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _instructions.length,
                      itemBuilder: (context, index) {
                        final instruction = _instructions[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: instruction.description,
                                  maxLines: 3,
                                  onChanged: (value) {
                                    setState(() {
                                      _instructions[index] = Instruction(
                                        stepNumber: instruction.stepNumber,
                                        description: value,
                                        videoUrl: instruction.videoUrl,
                                      );
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Step ${instruction.stepNumber}',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeInstruction(index),
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _saveRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF870C14),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Recipe',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
} 