import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/recipe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/nutrition_model.dart';
import '../../models/ingredient_model.dart';
import '../../models/instruction_model.dart';

class EditRecipeViewModel extends ChangeNotifier {
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

  late Recipe _originalRecipe;

  void initializeWithRecipe(Recipe recipe) {
    _originalRecipe = recipe;
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

  Future<void> pickCoverImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      coverImage = image;
      notifyListeners();
    }
  }

  String getId() {
    return _originalRecipe.id;
  }

  Widget coverImageWidget() {
    if (coverImage != null) {
      // If the path starts with http/https, treat as network image
      if (coverImage!.path.startsWith('http')) {
        return Image.network(
          coverImage!.path,
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        // Otherwise, treat as local file/blob
        return Image.file(
          File(coverImage!.path),
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      }
    }
    return Icon(Icons.add_photo_alternate, size: 50);
  }

  void addIngredient(Map<String, dynamic> ingredient) {
    ingredients.add(Ingredient.fromMap(ingredient));
    notifyListeners();
  }

  void removeIngredient(int index) {
    ingredients.removeAt(index);
    notifyListeners();
  }

  void addInstruction(Map<String, dynamic> instruction) {
    instructions.add(Instruction.fromMap(instruction));
    notifyListeners();
  }

  void removeInstruction(int index) {
    instructions.removeAt(index);
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

  Future<String> supabaseUpload({
    required String bucket,
    required String path,
    required dynamic fileOrBytes,
    required String contentType,
  }) async {
    if (kIsWeb) {
      final url =
          'https://sfkimpdnpxghevcpxvnj.supabase.co/storage/v1/object/$bucket/$path';
      final anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNma2ltcGRucHhnaGV2Y3B4dm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2Nzk0NjAsImV4cCI6MjA2NDI1NTQ2MH0.CSBv7uodAcyco-UaoC4OFSEqQE-z9gXG0ygH49FnnpQ';
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
          .upload(path, fileOrBytes,
              fileOptions: FileOptions(contentType: contentType));
      return Supabase.instance.client.storage
          .from(bucket)
          .getPublicUrl(response);
    }
  }

  void showAddIngredientDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
                decoration:
                    InputDecoration(labelText: 'Unit (e.g., g, ml, cups)'),
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
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  addIngredient({
                    'name': nameController.text,
                    'amount': double.tryParse(amountController.text) ?? 0,
                    'unit': unitController.text,
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

  void showAddInstructionDialog(BuildContext context) {
    final instructionController = TextEditingController();
    XFile? _selectedVideo;

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
                          final picked = await picker.pickVideo(
                              source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() {
                              _selectedVideo = picked;
                            });
                          }
                        },
                      ),
                      Text(_selectedVideo != null
                          ? "Video selected"
                          : "No video"),
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
                    final index = instructions.length + 1;
                    addInstruction({
                      'step': index,
                      'video': _selectedVideo,
                      'description': instructionController.text,
                      'localVideoPath': _selectedVideo?.path,
                    });
                    Navigator.pop(context);
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

  Future<Map<String, dynamic>> getChangedFields() async {
    final Map<String, dynamic> changed = {};

    if (titleController.text != _originalRecipe.title) {
      changed['title'] = titleController.text;
    }
    if (descriptionController.text != _originalRecipe.description) {
      changed['description'] = descriptionController.text;
    }
    if (servingsController.text != _originalRecipe.servings.toString()) {
      changed['servings'] = int.tryParse(servingsController.text) ?? 0;
    }
    if (prepTimeController.text != _originalRecipe.prepTime.toString()) {
      changed['prepTime'] = int.tryParse(prepTimeController.text) ?? 0;
    }
    if (cookTimeController.text != _originalRecipe.cookTime.toString()) {
      changed['cookTime'] = int.tryParse(cookTimeController.text) ?? 0;
    }
    if (selectedCategories.toString() !=
        _originalRecipe.categories.toString()) {
      changed['categories'] = selectedCategories;
    }
    // Compare cover image (if you store as URL or path)
    if (coverImage != null) {
      final isNetwork = coverImage!.path.startsWith('http');
      final originalIsNetwork = _originalRecipe.coverImage.startsWith('http');
      // If the type changed (network <-> file) or the path/url changed, mark as changed
      if (isNetwork != originalIsNetwork ||
          coverImage!.path != _originalRecipe.coverImage) {
        // Save new cover image
        String? imageUrl;
        if (kIsWeb) {
          final bytes = await coverImage!.readAsBytes();
          imageUrl = await supabaseUpload(
            bucket: 'recipeimages',
            path: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            fileOrBytes: bytes,
            contentType: 'image/jpeg',
          );
        } else {
          final file = File(coverImage!.path);
          imageUrl = await supabaseUpload(
            bucket: 'recipeimages',
            path: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            fileOrBytes: file,
            contentType: 'image/jpeg',
          );
        }

        // Delete old cover image
        if (_originalRecipe.coverImage.isNotEmpty) {
          final imagePath = _originalRecipe.coverImage;
          try {
            await Supabase.instance.client.storage
                .from('recipeimages')
                .remove([imagePath]);
          } catch (e) {
            throw Exception('Failed to delete old cover image: $e');
          }
        }
        changed['coverImage'] = imageUrl;
      }
    }
    // Compare ingredients and instructions as needed
    if (ingredients.toString() !=
        _originalRecipe.ingredients.map((i) => i.toMap()).toList().toString()) {
      changed['ingredients'] = ingredients;
    }
    // Nutrition info
    if (nutritionInfo.toString() !=
        _originalRecipe.nutritionInfo.toMap().toString()) {
      changed['nutritionInfo'] = nutritionInfo;
    }
    // Compare instructions
    for (var instruction in instructions) {
      // If the videoi is not null and is an xFile, upload it
      if (instruction.video != null && instruction.video is XFile) {
        final xfile = instruction.video as XFile;

        if (kIsWeb) {
          final fileSize = await xfile.length();

          if (fileSize > 50 * 1024 * 1024) {
            continue;
          }

          final bytes = await xfile.readAsBytes();
          final response = await supabaseUpload(
            bucket: 'instructionvideos',
            path:
                '${DateTime.now().millisecondsSinceEpoch}_${instruction.stepNumber}.mp4',
            fileOrBytes: bytes,
            contentType: 'video/mp4',
          );

          instruction.videoUrl = response; // 🟢 store the URL string
        } else {
          final file = File(xfile.path);
          int fileSize = await file.length();

          File fileToUpload = file;

          if (fileSize > 50 * 1024 * 1024) {
            final compressed = await VideoCompress.compressVideo(
              xfile.path,
              quality: VideoQuality.MediumQuality,
              deleteOrigin: false,
            );

            if (compressed != null && compressed.path != null) {
              fileToUpload = File(compressed.path!);
            }
          }

          final response = await supabaseUpload(
            bucket: 'instructionvideos',
            path:
                '${DateTime.now().millisecondsSinceEpoch}_${instruction.stepNumber}.mp4',
            fileOrBytes: fileToUpload,
            contentType: 'video/mp4',
          );

          instruction.videoUrl = response; // 🟢 store the URL string
        }
      }
    }
    // Prepare instructions for Firestore
    final sanitizedInstructions = instructions.map((instruction) {
      return {
        'step': instruction.stepNumber,
        'description': instruction.description,
        'videoUrl': instruction.videoUrl,
      };
    }).toList();

    if (sanitizedInstructions.toString() !=
        _originalRecipe.instructions
            .map((i) => i.toMap())
            .toList()
            .toString()) {
      changed['instructions'] = sanitizedInstructions;
    }

    // Nutrition info
    if (caloriesController.text !=
        _originalRecipe.nutritionInfo.calories.toString()) {
      changed['nutritionInfo']['calories'] =
          int.tryParse(caloriesController.text) ?? 0;
    }
    if (proteinController.text !=
        _originalRecipe.nutritionInfo.protein_g.toString()) {
      changed['nutritionInfo']['protein_g'] =
          int.tryParse(proteinController.text) ?? 0;
    }
    if (carbsController.text !=
        _originalRecipe.nutritionInfo.carbohydrates_total_g.toString()) {
      changed['nutritionInfo']['carbohydrates_total_g'] =
          int.tryParse(carbsController.text) ?? 0;
    }
    if (fatController.text !=
        _originalRecipe.nutritionInfo.fat_total_g.toString()) {
      changed['nutritionInfo']['fat_total_g'] =
          int.tryParse(fatController.text) ?? 0;
    }
    return changed;
  }

  Future<void> updateExistingRecipe(DocumentReference recipeRef) async {
    final changedFields = await getChangedFields();
    if (changedFields.isNotEmpty) {
      await recipeRef.update(changedFields);
    }
  }
}
