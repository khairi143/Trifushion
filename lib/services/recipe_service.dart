import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'recipes';

  // Get all recipes (for admin)
  Stream<List<Recipe>> getAllRecipes() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get recipes by author ID
  Stream<List<Recipe>> getRecipesByAuthor(String authorId) {
    return _firestore
        .collection(_collection)
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get public recipes only
  Stream<List<Recipe>> getPublicRecipes() {
    return _firestore
        .collection(_collection)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get a single recipe by ID
  Future<Recipe?> getRecipeById(String recipeId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(_collection).doc(recipeId).get();
      if (doc.exists) {
        return Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting recipe: $e');
      return null;
    }
  }

  // Add a new recipe
  Future<String?> addRecipe(Recipe recipe) async {
    try {
      DocumentReference docRef = await _firestore.collection(_collection).add(recipe.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding recipe: $e');
      return null;
    }
  }

  // Update an existing recipe
  Future<bool> updateRecipe(String recipeId, Recipe recipe) async {
    try {
      await _firestore.collection(_collection).doc(recipeId).update(recipe.toMap());
      return true;
    } catch (e) {
      print('Error updating recipe: $e');
      return false;
    }
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
  Future<List<Recipe>> searchRecipes(String query) async {
    try {
      // Note: This is a basic search. For production, consider using Algolia or Elasticsearch
      QuerySnapshot snapshot = await _firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .get();
      
      List<Recipe> allRecipes = snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Filter recipes that contain the query in title or description
      return allRecipes.where((recipe) =>
          recipe.title.toLowerCase().contains(query.toLowerCase()) ||
          recipe.description.toLowerCase().contains(query.toLowerCase())).toList();
    } catch (e) {
      print('Error searching recipes: $e');
      return [];
    }
  }

  // Get recipe statistics (for admin dashboard)
  Future<Map<String, int>> getRecipeStatistics() async {
    try {
      QuerySnapshot allRecipes = await _firestore.collection(_collection).get();
      QuerySnapshot publicRecipes = await _firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .get();
      
      return {
        'totalRecipes': allRecipes.docs.length,
        'publicRecipes': publicRecipes.docs.length,
        'privateRecipes': allRecipes.docs.length - publicRecipes.docs.length,
      };
    } catch (e) {
      print('Error getting recipe statistics: $e');
      return {
        'totalRecipes': 0,
        'publicRecipes': 0,
        'privateRecipes': 0,
      };
    }
  }

  // Get recipes with pagination (for better performance)
  Future<List<Recipe>> getRecipesWithPagination({
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
          .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting recipes with pagination: $e');
      return [];
    }
  }

  // Log admin actions
  Future<void> _logAdminAction(String actionType, Map<String, dynamic> details) async {
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
        DocumentReference docRef = _firestore.collection(_collection).doc(recipeId);
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

  // Toggle recipe visibility (Admin function)
  Future<bool> toggleRecipeVisibility(String recipeId, bool isPublic) async {
    try {
      await _firestore.collection(_collection).doc(recipeId).update({
        'isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log admin action
      await _logAdminAction('TOGGLE_RECIPE_VISIBILITY', {
        'recipeId': recipeId,
        'isPublic': isPublic,
        'action': 'Recipe visibility toggled by admin',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error toggling recipe visibility: $e');
      return false;
    }
  }
} 