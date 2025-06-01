import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../../services/auth_service.dart';
import '../../models/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

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
  
  XFile? _coverImage;
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
  Map<String, dynamic>? _lastCreatedRecipe;

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
        _coverImage = image;
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
    XFile? _selectedVideo;
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
                              _selectedVideo = picked;
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
                          'video': _selectedVideo, // Store as XFile
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

        // Upload cover image to Supabase
        String? imageUrl;
        if (_coverImage != null) {
          if (kIsWeb) {
            final bytes = await _coverImage!.readAsBytes();
            imageUrl = await supabaseUpload(
              bucket: 'recipeimages',
              path: '${DateTime.now().millisecondsSinceEpoch}.jpg',
              fileOrBytes: bytes,
              contentType: 'image/jpeg',
            );
          } else {
            final file = File(_coverImage!.path);
            imageUrl = await supabaseUpload(
              bucket: 'recipeimages',
              path: '${DateTime.now().millisecondsSinceEpoch}.jpg',
              fileOrBytes: file,
              contentType: 'image/jpeg',
            );
          }
        }

        // Upload instruction videos to Supabase
        for (var instruction in _instructions) {
          if (instruction['video'] != null && instruction['video'] is XFile) {
            if (kIsWeb) {
              final bytes = await instruction['video'].readAsBytes();
              final response = await supabaseUpload(
                bucket: 'instructionvideos',
                path: '${DateTime.now().millisecondsSinceEpoch}_${instruction['step']}.mp4',
                fileOrBytes: bytes,
                contentType: 'video/mp4',
              );
              instruction['video'] = response;
            } else {
              final file = File(instruction['video'].path);
              final response = await supabaseUpload(
                bucket: 'instructionvideos',
                path: '${DateTime.now().millisecondsSinceEpoch}_${instruction['step']}.mp4',
                fileOrBytes: file,
                contentType: 'video/mp4',
              );
              instruction['video'] = response;
            }
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
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': currentUser.uid,
          'createdByEmail': currentUser.email,
          'createdByName': currentUser.displayName ?? currentUser.email ?? '-',
        });

        setState(() {
          _lastCreatedRecipe = {
            'title': _titleController.text,
            'description': _descriptionController.text,
            'coverImage': imageUrl,
            'servings': _servingsController.text,
            'prepTime': _prepTimeController.text,
            'cookTime': _cookTimeController.text,
            'categories': _selectedCategories,
            'ingredients': _ingredients,
            'instructions': _instructions,
            'nutritionInfo': _nutritionInfo,
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recipe saved successfully!')),
        );
        // Automatically navigate back to the recipe list page
        Navigator.pop(context);
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
            kIsWeb
              ? FutureBuilder<Uint8List>(
                  future: _coverImage!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(snapshot.data!, height: 200, width: double.infinity, fit: BoxFit.cover),
                      );
                    } else {
                      return SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_coverImage!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(child: Text('${instruction['step']}')),
                    title: Text(instruction['description']),
                  ),
                  if (instruction['video'] != null && instruction['video'] is XFile)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: VideoPlayer(
                        VideoPlayerController.file(File(instruction['video'].path))
                          ..initialize().then((_) {
                            setState(() {});
                          }),
                      ),
                    ),
                ],
              );
            },
          ),
          if (_nutritionInfo['calories'] > 0 || _nutritionInfo['protein'] > 0 || 
              _nutritionInfo['carbs'] > 0 || _nutritionInfo['fat'] > 0) ...[
            SizedBox(height: 16),
            Text('Nutrition Information', style: Theme.of(context).textTheme.titleMedium),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNutritionRow('Calories', '${_nutritionInfo['calories']} kcal'),
                    _buildNutritionRow('Protein', '${_nutritionInfo['protein']}g'),
                    _buildNutritionRow('Carbs', '${_nutritionInfo['carbs']}g'),
                    _buildNutritionRow('Fat', '${_nutritionInfo['fat']}g'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Recipe'),
        leading: _isPreviewMode
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isPreviewMode = false;
                  });
                },
                tooltip: 'Back to Edit',
              )
            : null,
        actions: [
          if (!_isPreviewMode)
            IconButton(
              icon: Icon(Icons.preview),
              onPressed: () {
                setState(() {
                  _isPreviewMode = true;
                });
              },
              tooltip: 'Preview Mode',
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
                            ? (kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _coverImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(snapshot.data!, fit: BoxFit.cover),
                                        );
                                      } else {
                                        return Center(child: CircularProgressIndicator());
                                      }
                                    },
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(File(_coverImage!.path), fit: BoxFit.cover),
                                  ))
                            : Icon(Icons.add_photo_alternate, size: 50),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Recipe Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a recipe title';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
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
                              if (value == null || value.isEmpty) {
                                return 'Please enter number of servings';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _prepTimeController,
                            decoration: InputDecoration(labelText: 'Prep Time (minutes)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter prep time';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cookTimeController,
                            decoration: InputDecoration(labelText: 'Cook Time (minutes)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter cook time';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
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
                            decoration: InputDecoration(labelText: 'Calories (optional)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            decoration: InputDecoration(labelText: 'Protein (g) (optional)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
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
                            decoration: InputDecoration(labelText: 'Carbs (g) (optional)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            decoration: InputDecoration(labelText: 'Fat (g) (optional)'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
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
                    // Live preview of instructions with video icon
                    if (_instructions.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _instructions.length,
                        itemBuilder: (context, index) {
                          final instruction = _instructions[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text('${instruction['step']}')),
                            title: Text(instruction['description']),
                            subtitle: instruction['video'] != null
                                ? (instruction['video'] is String // Already uploaded, show preview
                                    ? Container(
                                        height: 150,
                                        child: VideoPlayerWidget(url: instruction['video']),
                                      )
                                    : (kIsWeb
                                        ? Row(
                                            children: [
                                              Icon(Icons.videocam, color: Colors.green),
                                              SizedBox(width: 4),
                                              Flexible(child: Text('Video will be available after saving')),
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Icon(Icons.videocam, color: Colors.green),
                                              SizedBox(width: 4),
                                              Flexible(child: Text('Video attached')),
                                            ],
                                          )))
                                : null,
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
                    // Save button at the bottom
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text('Save Recipe'),
                        onPressed: _saveRecipe,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({required this.url});
  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) => setState(() {}));
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : Center(child: CircularProgressIndicator());
  }
}

Future<String> supabaseUpload({
  required String bucket,
  required String path,
  required dynamic fileOrBytes,
  required String contentType,
}) async {
  if (kIsWeb) {
    final url = 'https://sfkimpdnpxghevcpxvnj.supabase.co/storage/v1/object/$bucket/$path';
    final anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNma2ltcGRucHhnaGV2Y3B4dm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2Nzk0NjAsImV4cCI6MjA2NDI1NTQ2MH0.CSBv7uodAcyco-UaoC4OFSEqQE-z9gXG0ygH49FnnpQ';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $anonKey',
        'apikey': anonKey,
        'Content-Type': contentType,
        'x-upsert': 'true',
      },
      body: fileOrBytes,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return 'https://sfkimpdnpxghevcpxvnj.supabase.co/storage/v1/object/public/$bucket/$path';
    } else {
      throw Exception('Failed to upload: ${response.body}');
    }
  } else {
    // Mobile/Desktop: Use Supabase client
    final response = await Supabase.instance.client.storage
        .from(bucket)
        .upload(path, fileOrBytes, fileOptions: FileOptions(contentType: contentType));
    return Supabase.instance.client.storage.from(bucket).getPublicUrl(response);
  }
} 