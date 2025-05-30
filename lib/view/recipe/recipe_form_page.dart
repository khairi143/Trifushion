import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../models/recipe.dart';

class RecipeFormPage extends StatefulWidget {
  final Recipe? recipe; // If provided, we're editing an existing recipe

  const RecipeFormPage({Key? key, this.recipe}) : super(key: key);

  @override
  _RecipeFormPageState createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servingsController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  File? _coverImage;
  List<String> _selectedCategories = [];
  List<Map<String, dynamic>> _ingredients = [];
  List<Map<String, dynamic>> _instructions = [];
  Map<String, dynamic> _nutritionInfo = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
  };
  bool _isPreviewMode = false;

  final List<String> _availableCategories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Snack',
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
  ];

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
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _coverImage = File(image.path);
      });
    }
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final amountController = TextEditingController();
        final unitController = TextEditingController();

        return AlertDialog(
          title: Text('Add Ingredient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Ingredient Name'),
              ),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitController,
                decoration: InputDecoration(labelText: 'Unit (e.g., g, ml, cups)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  setState(() {
                    _ingredients.add({
                      'name': nameController.text,
                      'amount': double.tryParse(amountController.text) ?? 0,
                      'unit': unitController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addInstruction() {
    File? _selectedVideo;
    final instructionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Instruction'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: instructionController,
                    decoration: InputDecoration(labelText: 'Step Description'),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.videocam),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final picked = await picker.pickVideo(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() {
                              _selectedVideo = File(picked.path);
                            });
                          }
                        },
                      ),
                      Text(_selectedVideo != null ? "Video selected" : "No video"),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (instructionController.text.isNotEmpty) {
                      setState(() {
                        _instructions.add({
                          'step': _instructions.length + 1,
                          'description': instructionController.text,
                          'video': _selectedVideo, // Store the file for now
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final currentUser = authService.currentUser;
        
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You must be logged in to save a recipe')),
          );
          return;
        }

        // Upload cover image if selected
        String? imageUrl;
        if (_coverImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('recipe_images')
              .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
          
          await storageRef.putFile(_coverImage!);
          imageUrl = await storageRef.getDownloadURL();
        }

        // Upload instruction videos and replace file with URL
        for (var instruction in _instructions) {
          if (instruction['video'] != null && instruction['video'] is File) {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('instruction_videos')
                .child('${DateTime.now().millisecondsSinceEpoch}_${instruction['step']}.mp4');
            await storageRef.putFile(instruction['video']);
            final videoUrl = await storageRef.getDownloadURL();
            instruction['video'] = videoUrl;
          }
        }

        // Save recipe to Firestore
        _nutritionInfo = {
          'calories': double.tryParse(_caloriesController.text) ?? 0,
          'protein': double.tryParse(_proteinController.text) ?? 0,
          'carbs': double.tryParse(_carbsController.text) ?? 0,
          'fat': double.tryParse(_fatController.text) ?? 0,
        };
        await FirebaseFirestore.instance.collection('recipes').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'coverImage': imageUrl,
          'servings': int.tryParse(_servingsController.text) ?? 0,
          'prepTime': int.tryParse(_prepTimeController.text) ?? 0,
          'cookTime': int.tryParse(_cookTimeController.text) ?? 0,
          'categories': _selectedCategories,
          'ingredients': _ingredients,
          'instructions': _instructions,
          'nutritionInfo': _nutritionInfo,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': currentUser.uid,
          'createdByEmail': currentUser.email,
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recipe saved successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recipe: $e')),
        );
      }
    }
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_coverImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_coverImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          SizedBox(height: 16),
          Text(_titleController.text, style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 8),
          Text(_descriptionController.text, style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.people, size: 20),
              SizedBox(width: 8),
              Text('${_servingsController.text} servings'),
              SizedBox(width: 16),
              Icon(Icons.timer, size: 20),
              SizedBox(width: 8),
              Text('${_prepTimeController.text} min prep + ${_cookTimeController.text} min cook'),
            ],
          ),
          SizedBox(height: 16),
          if (_selectedCategories.isNotEmpty) ...[
            Text('Categories', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: _selectedCategories.map((category) => Chip(label: Text(category))).toList(),
            ),
            SizedBox(height: 16),
          ],
          Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = _ingredients[index];
              return ListTile(
                title: Text('${ingredient['amount']} ${ingredient['unit']} ${ingredient['name']}'),
              );
            },
          ),
          SizedBox(height: 16),
          Text('Instructions', style: Theme.of(context).textTheme.titleMedium),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _instructions.length,
            itemBuilder: (context, index) {
              final instruction = _instructions[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${instruction['step']}')),
                title: Text(instruction['description']),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Recipe'),
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
            tooltip: _isPreviewMode ? 'Edit Mode' : 'Preview Mode',
          ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: _isPreviewMode
          ? _buildPreview()
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _coverImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_coverImage!, fit: BoxFit.cover),
                              )
                            : Icon(Icons.add_photo_alternate, size: 50),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a title' : null,
                    ),
                    SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Please enter a description' : null,
                    ),
                    SizedBox(height: 16),

                    // Servings and Time
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _servingsController,
                            decoration: InputDecoration(labelText: 'Servings'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter servings';
                              if (int.tryParse(value!) == null) return 'Please enter a valid number';
                              if (int.parse(value) <= 0) return 'Servings must be greater than 0';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _prepTimeController,
                            decoration: InputDecoration(labelText: 'Prep Time (min)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter prep time';
                              if (int.tryParse(value!) == null) return 'Please enter a valid number';
                              if (int.parse(value) < 0) return 'Time cannot be negative';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cookTimeController,
                            decoration: InputDecoration(labelText: 'Cook Time (min)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Please enter cook time';
                              if (int.tryParse(value!) == null) return 'Please enter a valid number';
                              if (int.parse(value) < 0) return 'Time cannot be negative';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Categories
                    Text('Categories', style: Theme.of(context).textTheme.titleMedium),
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
                    SizedBox(height: 16),

                    // Nutrition Info
                    Text('Nutrition Information', style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesController,
                            decoration: InputDecoration(labelText: 'Calories (kcal)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            decoration: InputDecoration(labelText: 'Protein (g)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            decoration: InputDecoration(labelText: 'Carbs (g)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            decoration: InputDecoration(labelText: 'Fat (g)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Ingredients
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: _addIngredient,
                        ),
                      ],
                    ),
                    if (_ingredients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Add at least one ingredient', style: TextStyle(color: Colors.red)),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = _ingredients[index];
                        return ListTile(
                          title: Text(ingredient['name']),
                          subtitle: Text('${ingredient['amount']} ${ingredient['unit']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _ingredients.removeAt(index);
                              });
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
                        Text('Instructions', style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: _addInstruction,
                        ),
                      ],
                    ),
                    if (_instructions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Add at least one instruction', style: TextStyle(color: Colors.red)),
                      ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _instructions.length,
                      itemBuilder: (context, index) {
                        final instruction = _instructions[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text('${instruction['step']}')),
                          title: Text(instruction['description']),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _instructions.removeAt(index);
                                // Update step numbers
                                for (var i = 0; i < _instructions.length; i++) {
                                  _instructions[i]['step'] = i + 1;
                                }
                              });
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
  }
} 