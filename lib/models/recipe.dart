import 'package:cloud_firestore/cloud_firestore.dart';
import 'ingredient_model.dart';
import 'instruction_model.dart';
import 'nutrition_model.dart';

// Original Recipe class for user view.
class Recipe {
  final String id;
  final String title;
  final String coverImage;
  int servings;
  final int prepTime; // in minutes
  final List<String> categories;
  final int cookTime; // in minutes
  final int totalTime; // in minutes
  final String description;
  final List<Ingredient> ingredients;
  final List<Instruction> instructions;
  final NutritionInfo nutritionInfo;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdByName;

  Recipe({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.servings,
    required this.prepTime,
    required this.categories,
    required this.cookTime,
    required this.totalTime,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.nutritionInfo,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByName,
  });

  // Add the copyWith method to update a recipe fields
  Recipe copyWith({
    String? title,
    String? coverImage,
    int? servings,
    int? prepTime,
    List<String>? categories,
    int? cookTime,
    int? totalTime,
    String? description,
    List<Ingredient>? ingredients,
    List<Instruction>? instructions,
    NutritionInfo? nutritionInfo,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByName,
  }) {
    return Recipe(
      id: this.id,
      title: title ?? this.title,
      coverImage: coverImage ?? this.coverImage,
      servings: servings ?? this.servings,
      prepTime: prepTime ?? this.prepTime,
      categories: categories ?? this.categories,
      cookTime: cookTime ?? this.cookTime,
      totalTime: totalTime ?? this.totalTime,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByName: createdByName ?? this.createdByName,
    );
  }

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      title: data['title'] ?? '',
      coverImage: data['coverImage'] ?? '',
      servings: data['servings'] ?? 0,
      prepTime: data['prepTime'] ?? 0,
      categories: List<String>.from(data['categories'] ?? []),
      cookTime: data['cookTime'] ?? 0,
      totalTime: data['totalTime'] ?? 0,
      description: data['description'] ?? '',
      ingredients: (data['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromMap(e))
              .toList() ??
          [],
      instructions: (data['instructions'] as List<dynamic>?)
              ?.map((e) => Instruction.fromMap(e))
              .toList() ??
          [],
      nutritionInfo: NutritionInfo.fromMap(data['nutritionInfo'] ?? {}),
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdByName: data['createdByName'] ?? '-',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'coverImage': coverImage,
      'servings': servings,
      'prepTime': prepTime,
      'categories': categories,
      'cookTime': cookTime,
      'totalTime': totalTime,
      'description': description,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'instructions': instructions.map((e) => e.toMap()).toList(),
      'nutritionInfo': nutritionInfo.toMap(),
      'userId': userId,
      'createdBy': userId,  // Add createdBy field for compatibility
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdByName': createdByName,
      'createdByEmail': createdByName,  // Add createdByEmail field
    };
  }
}
