import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String title;
  final String coverImage;
  final int servings;
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
          .toList() ?? [],
      instructions: (data['instructions'] as List<dynamic>?)
          ?.map((e) => Instruction.fromMap(e))
          .toList() ?? [],
      nutritionInfo: NutritionInfo.fromMap(data['nutritionInfo'] ?? {}),
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdByName': createdByName,
    };
  }
}

class Ingredient {
  final String name;
  final double amount;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? '',
      calories: (map['calories'] ?? 0.0).toDouble(),
      protein: (map['protein'] ?? 0.0).toDouble(),
      carbs: (map['carbs'] ?? 0.0).toDouble(),
      fat: (map['fat'] ?? 0.0).toDouble(),
      fiber: (map['fiber'] ?? 0.0).toDouble(),
      sugar: (map['sugar'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
    };
  }
}

class Instruction {
  final int stepNumber;
  final String description;
  final String? videoUrl;
  final int? duration; // in seconds

  Instruction({
    required this.stepNumber,
    required this.description,
    this.videoUrl,
    this.duration,
  });

  factory Instruction.fromMap(Map<String, dynamic> map) {
    return Instruction(
      stepNumber: map['stepNumber'] ?? 0,
      description: map['description'] ?? '',
      videoUrl: map['videoUrl'],
      duration: map['duration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'description': description,
      'videoUrl': videoUrl,
      'duration': duration,
    };
  }
}

class NutritionInfo {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
  });

  factory NutritionInfo.fromMap(Map<String, dynamic> map) {
    return NutritionInfo(
      calories: (map['calories'] ?? 0.0).toDouble(),
      protein: (map['protein'] ?? 0.0).toDouble(),
      carbs: (map['carbs'] ?? 0.0).toDouble(),
      fat: (map['fat'] ?? 0.0).toDouble(),
      fiber: (map['fiber'] ?? 0.0).toDouble(),
      sugar: (map['sugar'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
    };
  }
} 