import 'package:cloud_firestore/cloud_firestore.dart';

// This one create by bosheng, so... just for admin use, please don't confuse Khair.
class RecipeModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double rating;
  final String authorId;
  final String authorName;
  final List<String> ingredients;
  final List<String> instructions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;

  RecipeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.authorId,
    required this.authorName,
    required this.ingredients,
    required this.instructions,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = true,
  });

  // Convert Recipe object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'authorId': authorId,
      'authorName': authorName,
      'ingredients': ingredients,
      'instructions': instructions,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPublic': isPublic,
    };
  }

  // Create Recipe object from Firestore document
  factory RecipeModel.fromMap(Map<String, dynamic> map, String documentId) {
    // Add debugging information
    print('Creating Recipe from data: $map');

    return RecipeModel(
      id: documentId,
      title: _parseString(map['title']) ?? 'Untitled Recipe',
      description: _parseString(map['description']) ?? 'No description available',
      imageUrl: _parseString(map['imageUrl']) ?? '',
      rating: _parseDouble(map['rating']) ?? 0.0,
      authorId: _parseString(map['createdBy']) ?? _parseString(map['authorId']) ?? '',
      authorName: _parseString(map['createdByName']) ?? _parseString(map['authorName']) ?? '',
      ingredients: _parseStringList(map['ingredients']) ?? [],
      instructions: _parseStringList(map['instructions']) ?? [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: map['isPublic'] == true,
    );
  }

  // Helper method to safely parse string values
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    return value.toString().trim().isEmpty ? null : value.toString().trim();
  }

  // Helper method to safely parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // Helper method to safely parse List<String> from dynamic data
  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String) {
      // If it's a single string, return it as a list with one item
      return value.trim().isNotEmpty ? [value.trim()] : null;
    }
    return null;
  }

  // Create a copy of Recipe with updated fields
  RecipeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    double? rating,
    String? authorId,
    String? authorName,
    List<String>? ingredients,
    List<String>? instructions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublic,
  }) {
    return RecipeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
