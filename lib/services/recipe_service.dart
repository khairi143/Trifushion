import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/recipe.dart';
import '../models/recipe_model.dart';

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
        final storageRef = _storage.ref().child(
            'recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
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
  Future<void> updateRecipe(String id, Recipe recipe,
      {File? newCoverImage}) async {
    try {
      String? imageUrl;
      if (newCoverImage != null) {
        final storageRef = _storage.ref().child(
            'recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(newCoverImage);
        imageUrl = await storageRef.getDownloadURL();

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
  
  Future<String> uploadImageToStorage(File coverImage) async {
  try {
    final storageRef = _storage.ref().child('recipe_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await storageRef.putFile(File(coverImage.path));
    return await storageRef.getDownloadURL();
  } catch (e) {
    throw Exception('Failed to upload image: $e');
  }
}

  
// Delete recipe (User)
Future<bool> userDeleteRecipe(String recipeId, String userId, String coverImageUrl) async {
  try {
    // Get the recipe document to verify the user who created it
    final doc = await _firestore.collection(_collection).doc(recipeId).get();

    if (!doc.exists) {
      throw Exception('Recipe not found');
    }

    // Get user from the recipe data to verify ownership
    final recipeData = doc.data() as Map<String, dynamic>;
    final createdBy = recipeData['createdBy'];

    if (createdBy != userId) {
      throw Exception('You do not have permission to delete this recipe');
    }

    await _firestore.collection(_collection).doc(recipeId).delete();

    // delete image
    if (coverImageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(coverImageUrl).delete();
        print("Cover image deleted successfully");
      } catch (e) {
        print("Error deleting cover image: $e");
      }
    }

    return true;
  } catch (e) {
    print('Error deleting recipe: $e');
    return false;
  }
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
        .map((snapshot) =>
            snapshot.docs.map((doc) => Recipe.fromFirestore(doc)).toList());
  }

  // Search recipes by title
  Stream<List<Recipe>> searchRecipesUser(String query) {
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

  // Delete a recipe (Admin function)
  Future<bool> deleteRecipe(String recipeId) async {
    try {
      await _firestore.collection(_collection).doc(recipeId).delete();

      // Log admin action
      await _logAdminAction('DELETE_RECIPE', {
        'recipeId': recipeId,
        'action': 'Recipe deleted by admin',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error deleting recipe: $e');
      return false;
    }
  }

  // Search recipes by title or description
  Future<List<RecipeModel>> searchRecipes(String query) async {
    try {
      // Note: This is a basic search. For production, consider using Algolia or Elasticsearch
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .get();

      List<RecipeModel> allRecipes = snapshot.docs
          .map((doc) =>
              RecipeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filter recipes that contain the query in title or description
      return allRecipes
          .where((recipe) =>
              recipe.title.toLowerCase().contains(query.toLowerCase()) ||
              recipe.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

  // Get recipe statistics (for admin dashboard)
  Future<Map<String, int>> getRecipeStatistics() async {
    try {
      QuerySnapshot allRecipes = await _firestore.collection(_collection).get();
      return {
        'totalRecipes': allRecipes.docs.length,
      };
    } catch (e) {
      print('Error getting recipe statistics: $e');
      return {
        'totalRecipes': 0,
      };
    }
  }

  // Get all recipes (for admin)
  Stream<List<RecipeModel>> getAllRecipes() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<RecipeModel>> getRecipesByAuthor(String authorId) {
    return _firestore
        .collection(_collection)
        .where('authorId', isEqualTo: authorId)
        .snapshots()
        .map((snapshot) {
          List<RecipeModel> recipes = snapshot.docs
              .map((doc) => RecipeModel.fromMap(doc.data(), doc.id))
              .toList();
          
          // Sort by creation date in memory to avoid index requirement
          recipes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return recipes;
        });
  }

  // Get recipes with pagination (for better performance)
  Future<List<RecipeModel>> getRecipesWithPagination({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    bool publicOnly = false,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (publicOnly) {
        query = query.where('isPublic', isEqualTo: true);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();
      return snapshot.docs
          .map((doc) =>
              RecipeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting recipes with pagination: $e');
      return [];
    }
  }

  // Log admin actions
  Future<void> _logAdminAction(
      String actionType, Map<String, dynamic> details) async {
    try {
      await _firestore.collection('adminActions').add({
        'actionType': actionType,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging admin action: $e');
    }
  }

  // Bulk delete recipes (Admin function)
  Future<int> bulkDeleteRecipes(List<String> recipeIds) async {
    int deletedCount = 0;
    WriteBatch batch = _firestore.batch();

    try {
      for (String recipeId in recipeIds) {
        DocumentReference docRef =
            _firestore.collection(_collection).doc(recipeId);
        batch.delete(docRef);
      }

      await batch.commit();
      deletedCount = recipeIds.length;

      // Log admin action
      await _logAdminAction('BULK_DELETE_RECIPES', {
        'recipeIds': recipeIds,
        'deletedCount': deletedCount,
        'action': 'Bulk delete recipes by admin',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error in bulk delete: $e');
    }

    return deletedCount;
  }

  // Filter recipes by ingredients
  Stream<List<Recipe>> filterRecipesByIngredients(
      List<String> includedIngredients, List<String> excludedIngredients) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .where((recipe) {
            // Convert recipe ingredients to lowercase for case-insensitive comparison
            final recipeIngredients = recipe.ingredients
                .map((ing) => ing.name.toLowerCase())
                .toList();

            // Check if all included ingredients are present
            final hasAllIncluded = includedIngredients.isEmpty ||
                includedIngredients.every((ingredient) => recipeIngredients
                    .any((ri) => ri.contains(ingredient.toLowerCase())));

            // Check if none of the excluded ingredients are present
            final hasNoExcluded = excludedIngredients.isEmpty ||
                !excludedIngredients.any((ingredient) => recipeIngredients
                    .any((ri) => ri.contains(ingredient.toLowerCase())));

            return hasAllIncluded && hasNoExcluded;
          })
          .toList();
    });
  }

  // Combined search and filter
  Stream<List<Recipe>> searchAndFilterRecipes(String query,
      List<String> includedIngredients, List<String> excludedIngredients) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Recipe.fromFirestore(doc))
          .where((recipe) {
            // Text search match
            final matchesQuery = query.isEmpty ||
                recipe.title.toLowerCase().contains(query.toLowerCase()) ||
                recipe.description.toLowerCase().contains(query.toLowerCase());

            // Convert recipe ingredients to lowercase for case-insensitive comparison
            final recipeIngredients = recipe.ingredients
                .map((ing) => ing.name.toLowerCase())
                .toList();

            // Check if all included ingredients are present
            final hasAllIncluded = includedIngredients.isEmpty ||
                includedIngredients.every((ingredient) => recipeIngredients
                    .any((ri) => ri.contains(ingredient.toLowerCase())));

            // Check if none of the excluded ingredients are present
            final hasNoExcluded = excludedIngredients.isEmpty ||
                !excludedIngredients.any((ingredient) => recipeIngredients
                    .any((ri) => ri.contains(ingredient.toLowerCase())));

            return matchesQuery && hasAllIncluded && hasNoExcluded;
          })
          .toList();
    });
  }
}
