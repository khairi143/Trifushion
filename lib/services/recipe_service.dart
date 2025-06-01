import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/recipe.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'recipes';

  // Create a new recipe
  Future<String> createRecipe(Recipe recipe, File? coverImage) async {
    try {
      String? imageUrl;
      if (coverImage != null) {
        // Upload cover image to Firebase Storage
        final storageRef = _storage.ref().child('recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(coverImage);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Create recipe document with image URL
      final recipeData = recipe.toMap();
      if (imageUrl != null) {
        recipeData['coverImage'] = imageUrl;
      }

      final docRef = await _firestore.collection(_collection).add(recipeData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create recipe: $e');
    }
  }

  // Get a single recipe by ID
  Future<Recipe> getRecipe(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        throw Exception('Recipe not found');
      }
      return Recipe.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get recipe: $e');
    }
  }

  // Get all recipes
  Stream<List<Recipe>> getRecipes() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

  // Get recipes by category
  Stream<List<Recipe>> getRecipesByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('categories', arrayContains: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

  // Update a recipe
  Future<void> updateRecipe(String id, Recipe recipe, {File? newCoverImage}) async {
    try {
      String? imageUrl;
      if (newCoverImage != null) {
        // Upload new cover image
        final storageRef = _storage.ref().child('recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(newCoverImage);
        imageUrl = await storageRef.getDownloadURL();

        // Delete old image if exists
        if (recipe.coverImage.isNotEmpty) {
          try {
            await _storage.refFromURL(recipe.coverImage).delete();
          } catch (e) {
            print('Failed to delete old image: $e');
          }
        }
      }

      final recipeData = recipe.toMap();
      if (imageUrl != null) {
        recipeData['coverImage'] = imageUrl;
      }
      recipeData['updatedAt'] = Timestamp.now();

      await _firestore.collection(_collection).doc(id).update(recipeData);
    } catch (e) {
      throw Exception('Failed to update recipe: $e');
    }
  }

  // Delete a recipe
  Future<void> deleteRecipe(String id, String coverImageUrl) async {
    try {
      // Delete cover image from storage
      if (coverImageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(coverImageUrl).delete();
        } catch (e) {
          print('Failed to delete image: $e');
        }
      }

      // Delete recipe document
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  // Search recipes by title
  Stream<List<Recipe>> searchRecipes(String query) {
    return _firestore
        .collection(_collection)
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('title')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

  // Get user's recipes
  Stream<List<Recipe>> getUserRecipes(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList();
    });
  }

  // Stream recipes created by a given user (using a Firestore query)
  Stream<List<Recipe>> getMyRecipes(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection("recipes")
        .where("createdBy", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }
} 