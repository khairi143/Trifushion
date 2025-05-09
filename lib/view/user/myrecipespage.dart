import 'package:flutter/material.dart';
import '../../view_models/home_view_model.dart' as home;

class Cookbook {
  final String id;
  final String name;
  final List<home.Recipe> recipes;

  Cookbook({
    required this.id,
    required this.name,
    this.recipes = const [],
  });
}

class MyRecipesPage extends StatefulWidget {
  const MyRecipesPage({super.key});

  @override
  State<MyRecipesPage> createState() => _MyRecipesPageState();
}

class _MyRecipesPageState extends State<MyRecipesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Cookbook> _cookbooks = [];
  Cookbook? _selectedCookbook;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // TODO: Load saved cookbooks from storage
    _cookbooks = [
      Cookbook(id: '1', name: 'Breakfast'),
      Cookbook(id: '2', name: 'Lunch'),
      Cookbook(id: '3', name: 'Dinner'),
    ];
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
            // TODO: Navigate to create recipe page
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.book : Icons.add),
        tooltip: _tabController.index == 0 ? 'Create New Cookbook' : 'Create New Recipe',
      ),
    );
  }

  Widget _buildSavedRecipes() {
    return Column(
      children: [
        // Cookbook List
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _cookbooks.length + 1, // +1 for "All" option
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCookbookChip(
                  name: 'All',
                  isSelected: _selectedCookbook == null,
                  onTap: () {
                    setState(() {
                      _selectedCookbook = null;
                    });
                  },
                );
              }
              final cookbook = _cookbooks[index - 1];
              return _buildCookbookChip(
                name: cookbook.name,
                isSelected: _selectedCookbook?.id == cookbook.id,
                onTap: () {
                  setState(() {
                    _selectedCookbook = cookbook;
                  });
                },
                onLongPress: () {
                  _showCookbookOptions(context, cookbook);
                },
              );
            },
          ),
        ),
        // Recipes List
        Expanded(
          child: _selectedCookbook == null
              ? _buildAllRecipesList()
              : _buildCookbookRecipesList(_selectedCookbook!),
        ),
      ],
    );
  }

  Widget _buildCookbookChip({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Chip(
          label: Text(name),
          backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          onDeleted: onLongPress != null ? () => onLongPress() : null,
          deleteIcon: onLongPress != null ? const Icon(Icons.more_vert) : null,
        ),
      ),
    );
  }

  Widget _buildAllRecipesList() {
    // TODO: Replace with actual saved recipes
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Placeholder count
      itemBuilder: (context, index) {
        return _buildRecipeCard(
          title: 'Recipe ${index + 1}',
          description: 'Description for recipe ${index + 1}',
          onTap: () {
            // TODO: Navigate to recipe details
          },
          onMove: () {
            _showMoveToCookbookDialog(context);
          },
        );
      },
    );
  }

  Widget _buildCookbookRecipesList(Cookbook cookbook) {
    // TODO: Replace with actual cookbook recipes
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cookbook.recipes.length,
      itemBuilder: (context, index) {
        final recipe = cookbook.recipes[index];
        return _buildRecipeCard(
          title: recipe.title,
          description: recipe.description,
          onTap: () {
            // TODO: Navigate to recipe details
          },
          onMove: () {
            _showMoveToCookbookDialog(context);
          },
        );
      },
    );
  }

  Widget _buildRecipeCard({
    required String title,
    required String description,
    required VoidCallback onTap,
    required VoidCallback onMove,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'images/greek_salad.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () {
                // TODO: Remove from saved recipes
              },
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_move),
              onPressed: onMove,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showRecipeOptions(context);
              },
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showCreateCookbookDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Cookbook'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter cookbook name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _cookbooks.add(Cookbook(
                      id: DateTime.now().toString(),
                      name: controller.text,
                    ));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showCookbookOptions(BuildContext context, Cookbook cookbook) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename Cookbook'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameCookbookDialog(context, cookbook);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Cookbook'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteCookbookConfirmation(context, cookbook);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameCookbookDialog(BuildContext context, Cookbook cookbook) {
    final TextEditingController controller = TextEditingController(text: cookbook.name);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Cookbook'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter new cookbook name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    final index = _cookbooks.indexWhere((c) => c.id == cookbook.id);
                    if (index != -1) {
                      _cookbooks[index] = Cookbook(
                        id: cookbook.id,
                        name: controller.text,
                        recipes: cookbook.recipes,
                      );
                    }
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteCookbookConfirmation(BuildContext context, Cookbook cookbook) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Cookbook'),
          content: const Text('Are you sure you want to delete this cookbook? All recipes in this cookbook will be moved to "All".'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cookbooks.removeWhere((c) => c.id == cookbook.id);
                  if (_selectedCookbook?.id == cookbook.id) {
                    _selectedCookbook = null;
                  }
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showMoveToCookbookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Move to Cookbook'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _cookbooks.length,
              itemBuilder: (context, index) {
                final cookbook = _cookbooks[index];
                return ListTile(
                  title: Text(cookbook.name),
                  onTap: () {
                    // TODO: Implement move recipe to cookbook
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreatedRecipes() {
    // TODO: Replace with actual created recipes
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Placeholder count
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'images/greek_salad.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text('Created Recipe ${index + 1}'),
            subtitle: Text('Description for created recipe ${index + 1}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Navigate to edit recipe
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _showDeleteConfirmation(context);
                  },
                ),
              ],
            ),
            onTap: () {
              // TODO: Navigate to recipe details
            },
          ),
        );
      },
    );
  }

  void _showRecipeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share Recipe'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement share functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove from Saved'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this recipe?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement delete functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recipe deleted')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
} 