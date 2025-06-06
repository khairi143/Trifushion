import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe.dart';
import '../../services/recipe_service.dart';
import '../recipe/recipe_detail_page.dart';
import '../recipe/recipe_form_page.dart';
import '../recipe/edit_recipe_page.dart';

class MyRecipesPage extends StatefulWidget {
  MyRecipesPage({Key? key}) : super(key: key);

  @override
  _MyRecipesPageState createState() => _MyRecipesPageState();
}

class _MyRecipesPageState extends State<MyRecipesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RecipeService _recipeService = RecipeService();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Saved Recipes'),
            Tab(text: 'Created Recipes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedRecipes(),
          _buildCreatedRecipes(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreateCookbookDialog(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecipeFormPage()),
            );
          }
        },
        child: Icon(Icons.add),
        tooltip: _tabController.index == 0 ? 'Create New Cookbook' : 'Create New Recipe',
      ),
    );
  }

  Widget _buildSavedRecipes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(_currentUserId)
          .collection("bookmarks")
          .orderBy("savedAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final bookmarkDocs = snapshot.data?.docs ?? [];
        if (bookmarkDocs.isEmpty) {
          return Center(child: Text("No saved recipes."));
        }
        return ListView.builder(
          itemCount: bookmarkDocs.length,
          itemBuilder: (context, i) {
            final bookmark = bookmarkDocs[i];
            final recipeId = bookmark.get("recipeId") as String?;
            print('Bookmark recipeId: $recipeId');
            if (recipeId == null) return SizedBox.shrink();

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection("recipes").doc(recipeId).snapshots(),
              builder: (context, recipeSnapshot) {
                if (recipeSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (recipeSnapshot.hasError || !recipeSnapshot.hasData) {
                  return SizedBox.shrink();
                }
                final recipeData = recipeSnapshot.data!.data() as Map<String, dynamic>?;
                print('Recipe data for $recipeId: $recipeData');
                if (recipeData == null) return SizedBox.shrink();
                final recipe = Recipe.fromFirestore(recipeSnapshot.data!);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: recipe.coverImage != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(recipe.coverImage!, width: 60, height: 60, fit: BoxFit.cover)) : Icon(Icons.image, size: 60, color: Colors.grey),
                    title: Text(recipe.title, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(recipe.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailPage(recipe: recipe))),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCreatedRecipes() {
    return StreamBuilder<List<Recipe>>(
      stream: _recipeService.getMyRecipes(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final myRecipes = snapshot.data ?? [];
        if (myRecipes.isEmpty) {
          return Center(child: Text("No recipes created yet."));
        }
        return ListView.builder(
          itemCount: myRecipes.length,
          itemBuilder: (context, i) {
            final recipe = myRecipes[i];

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: recipe.coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(recipe.coverImage!, width: 60, height: 60, fit: BoxFit.cover),
                      )
                    : Icon(Icons.image, size: 60, color: Colors.grey),
                title: Text(recipe.title, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(recipe.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _navigateToEditRecipePage(recipe),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteRecipe(recipe),
                    ),
                  ],
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailPage(recipe: recipe))),
              ),
            );
          },
        );
      },
    );
  }

  // Edit recipe
  void _navigateToEditRecipePage(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRecipePage(recipe: recipe),
      ),
    );
  }

  // Delete recipe
  void _deleteRecipe(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Recipe"),
        content: Text("Are you sure you want to delete this recipe?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await _recipeService.userDeleteRecipe(recipe.id, _currentUserId, recipe.coverImage ?? '');
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recipe deleted successfully')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting recipe')));
              }
            },
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showCreateCookbookDialog(BuildContext context) {
    // Implementation of _showCreateCookbookDialog method
  }
} 