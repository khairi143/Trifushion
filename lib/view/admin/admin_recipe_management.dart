import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';
import '../../services/recipe_service.dart';

class AdminRecipeManagement extends StatefulWidget {
  const AdminRecipeManagement({Key? key}) : super(key: key);

  @override
  _AdminRecipeManagementState createState() => _AdminRecipeManagementState();
}

class _AdminRecipeManagementState extends State<AdminRecipeManagement> {
  final RecipeService _recipeService = RecipeService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  String _filterVisibility = 'all'; // 'all', 'public', 'private'
  String _sortBy = 'date'; // 'date', 'title', 'author', 'rating'
  bool _sortAscending = false;
  List<String> _selectedRecipeIds = [];
  bool _isSelectionMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Controls
          _buildSearchAndFilters(),
          // Recipe Statistics
          _buildRecipeStats(),
          // Selection Controls (when in selection mode)
          if (_isSelectionMode) _buildSelectionControls(),
          // Recipe List
          Expanded(child: _buildRecipeList()),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton(
              onPressed: _exitSelectionMode,
              backgroundColor: Colors.grey,
              child: const Icon(Icons.close),
              tooltip: 'Cancel Selection',
            )
          : FloatingActionButton(
              onPressed: _toggleSelectionMode,
              child: const Icon(Icons.select_all),
              tooltip: 'Select Multiple',
            ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Recipes',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filter and Sort Controls
          Row(
            children: [
              // Visibility Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _filterVisibility,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.visibility),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Recipes')),
                      DropdownMenuItem(value: 'public', child: Text('Public Only')),
                      DropdownMenuItem(value: 'private', child: Text('Private Only')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterVisibility = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort Options
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.sort),
                    items: const [
                      DropdownMenuItem(value: 'date', child: Text('Sort by Date')),
                      DropdownMenuItem(value: 'title', child: Text('Sort by Title')),
                      DropdownMenuItem(value: 'author', child: Text('Sort by Author')),
                      DropdownMenuItem(value: 'rating', child: Text('Sort by Rating')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Sort Direction
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                  tooltip: _sortAscending ? 'Ascending' : 'Descending',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeStats() {
    return FutureBuilder<Map<String, int>>(
      future: _recipeService.getRecipeStatistics(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final stats = snapshot.data!;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Total', stats['totalRecipes'].toString(), Colors.blue, Icons.restaurant),
                _buildStatCard('Public', stats['publicRecipes'].toString(), Colors.green, Icons.public),
                _buildStatCard('Private', stats['privateRecipes'].toString(), Colors.orange, Icons.lock),
                if (_isSelectionMode)
                  _buildStatCard('Selected', _selectedRecipeIds.length.toString(), Colors.purple, Icons.check_circle),
              ],
            ),
          );
        }
        return const SizedBox(height: 60);
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.purple.withOpacity(0.3)),
          bottom: BorderSide(color: Colors.purple.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedRecipeIds.length} selected',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_selectedRecipeIds.isNotEmpty) ...[
            ElevatedButton.icon(
              onPressed: _bulkDeleteRecipes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete),
              label: const Text('Delete Selected'),
            ),
            const SizedBox(width: 8),
          ],
          TextButton(
            onPressed: _clearSelection,
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    return StreamBuilder<List<Recipe>>(
      stream: _recipeService.getAllRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading recipes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No recipes found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Recipes will appear here once users create them',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        List<Recipe> recipes = snapshot.data!;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          recipes = recipes.where((recipe) {
            return recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                recipe.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                recipe.authorName.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();
        }

        // Apply visibility filter
        if (_filterVisibility != 'all') {
          recipes = recipes.where((recipe) {
            if (_filterVisibility == 'public') return recipe.isPublic;
            if (_filterVisibility == 'private') return !recipe.isPublic;
            return true;
          }).toList();
        }

        // Apply sorting
        recipes.sort((a, b) {
          dynamic valueA, valueB;
          
          switch (_sortBy) {
            case 'title':
              valueA = a.title.toLowerCase();
              valueB = b.title.toLowerCase();
              break;
            case 'author':
              valueA = a.authorName.toLowerCase();
              valueB = b.authorName.toLowerCase();
              break;
            case 'rating':
              valueA = a.rating;
              valueB = b.rating;
              break;
            case 'date':
            default:
              valueA = a.createdAt;
              valueB = b.createdAt;
          }
          
          if (valueA is DateTime && valueB is DateTime) {
            return _sortAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
          } else if (valueA is double && valueB is double) {
            return _sortAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
          } else {
            return _sortAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
          }
        });

        if (recipes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No recipes match your criteria',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filter settings',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            final recipe = recipes[index];
            final isSelected = _selectedRecipeIds.contains(recipe.id);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 2,
              color: isSelected ? Colors.purple.withOpacity(0.1) : null,
              child: ListTile(
                leading: _isSelectionMode
                    ? Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleRecipeSelection(recipe.id),
                      )
                    : _buildRecipeImage(recipe.imageUrl),
                title: Text(
                  recipe.title.isNotEmpty ? recipe.title : 'Untitled Recipe',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.description.isNotEmpty ? recipe.description : 'No description available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          recipe.isPublic ? Icons.public : Icons.lock,
                          size: 16,
                          color: recipe.isPublic ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'by ${recipe.authorName.isNotEmpty ? recipe.authorName : 'Unknown User'}',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text('${recipe.rating}'),
                      ],
                    ),
                  ],
                ),
                trailing: _isSelectionMode
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (value) => _handleRecipeAction(value, recipe),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'view_details',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'view_user_recipes',
                            child: Row(
                              children: [
                                Icon(Icons.person_search, color: Colors.purple),
                                const SizedBox(width: 8),
                                Text('View User Recipes'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle_visibility',
                            child: Row(
                              children: [
                                Icon(recipe.isPublic ? Icons.lock : Icons.public),
                                const SizedBox(width: 8),
                                Text(recipe.isPublic ? 'Make Private' : 'Make Public'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                onTap: _isSelectionMode
                    ? () => _toggleRecipeSelection(recipe.id)
                    : () => _showRecipeDetails(recipe),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecipeImage(String imageUrl) {
    return SizedBox(
      width: 50,
      height: 50,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
              )
            : _buildDefaultImage(),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.restaurant_menu, color: Colors.grey),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedRecipeIds.clear();
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedRecipeIds.clear();
    });
  }

  void _toggleRecipeSelection(String recipeId) {
    setState(() {
      if (_selectedRecipeIds.contains(recipeId)) {
        _selectedRecipeIds.remove(recipeId);
      } else {
        _selectedRecipeIds.add(recipeId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedRecipeIds.clear();
    });
  }

  void _handleRecipeAction(String action, Recipe recipe) {
    switch (action) {
      case 'view_details':
        _showRecipeDetails(recipe);
        break;
      case 'view_user_recipes':
        _showUserRecipesDialog(recipe.authorId, recipe.authorName);
        break;
      case 'toggle_visibility':
        _toggleRecipeVisibility(recipe);
        break;
      case 'delete':
        _showDeleteConfirmation(recipe);
        break;
    }
  }

  void _toggleRecipeVisibility(Recipe recipe) async {
    setState(() => _isLoading = true);
    
    bool success = await _recipeService.toggleRecipeVisibility(recipe.id, !recipe.isPublic);
    
    setState(() => _isLoading = false);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recipe visibility updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update recipe visibility'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecipe(recipe.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteRecipe(String recipeId) async {
    setState(() => _isLoading = true);
    
    bool success = await _recipeService.deleteRecipe(recipeId);
    
    setState(() => _isLoading = false);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete recipe'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _bulkDeleteRecipes() {
    if (_selectedRecipeIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Recipes'),
        content: Text('Are you sure you want to delete ${_selectedRecipeIds.length} selected recipes? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performBulkDelete() async {
    setState(() => _isLoading = true);
    
    int deletedCount = await _recipeService.bulkDeleteRecipes(_selectedRecipeIds);
    
    setState(() {
      _isLoading = false;
      _selectedRecipeIds.clear();
      _isSelectionMode = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$deletedCount recipes deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with recipe image and basic info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.purple.shade50],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Recipe Image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: recipe.imageUrl.isNotEmpty
                                ? Image.network(
                                    recipe.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildDefaultImage(),
                                  )
                                : _buildDefaultImage(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Basic Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title.isNotEmpty ? recipe.title : 'Untitled Recipe',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'by ${recipe.authorName.isNotEmpty ? recipe.authorName : 'Unknown User'}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text('${recipe.rating}'),
                                  const SizedBox(width: 16),
                                  Icon(
                                    recipe.isPublic ? Icons.public : Icons.lock,
                                    size: 16,
                                    color: recipe.isPublic ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    recipe.isPublic ? 'Public' : 'Private',
                                    style: TextStyle(
                                      color: recipe.isPublic ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      _buildSectionTitle('Description'),
                      Text(
                        recipe.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      
                      // Recipe Info
                      _buildSectionTitle('Recipe Information'),
                      _buildInfoCard([
                        _buildInfoRow(Icons.person, 'Author Name', recipe.authorName.isNotEmpty ? recipe.authorName : 'Unknown User'),
                        _buildInfoRow(Icons.badge, 'Author ID', recipe.authorId.isNotEmpty ? recipe.authorId : 'N/A'),
                        _buildInfoRow(Icons.access_time, 'Created', 
                          _formatDateTime(recipe.createdAt)),
                        _buildInfoRow(Icons.update, 'Last Updated', 
                          _formatDateTime(recipe.updatedAt)),
                        _buildInfoRow(Icons.star_rate, 'Rating', '${recipe.rating}/5.0'),
                        _buildInfoRow(
                          recipe.isPublic ? Icons.public : Icons.lock, 
                          'Visibility', 
                          recipe.isPublic ? 'Public' : 'Private',
                          valueColor: recipe.isPublic ? Colors.green : Colors.orange,
                        ),
                      ]),
                      
                      // Ingredients
                      if (recipe.ingredients.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionTitle('Ingredients (${recipe.ingredients.length})'),
                        _buildInfoCard(
                          recipe.ingredients.asMap().entries.map((entry) => 
                            _buildIngredientRow(entry.key + 1, _formatIngredient(entry.value))
                          ).toList(),
                        ),
                      ],
                      
                      // Instructions
                      if (recipe.instructions.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionTitle('Instructions (${recipe.instructions.length} steps)'),
                        _buildInfoCard(
                          recipe.instructions.asMap().entries.map((entry) => 
                            _buildInstructionRow(entry.key + 1, _formatInstruction(entry.value))
                          ).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showUserRecipesDialog(recipe.authorId, recipe.authorName);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.person_search),
                        label: const Text('View User Recipes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleRecipeVisibility(recipe);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: recipe.isPublic ? Colors.orange : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(recipe.isPublic ? Icons.lock : Icons.public),
                        label: Text(recipe.isPublic ? 'Make Private' : 'Make Public'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(recipe);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientRow(int index, String ingredient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ingredient,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(int step, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserRecipesDialog(String authorId, String authorName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.purple.shade50, Colors.blue.shade50],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      radius: 25,
                      child: Icon(Icons.person, color: Colors.purple.shade700, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$authorName\'s Recipes',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'User ID: $authorId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Recipes List
              Expanded(
                child: StreamBuilder<List<Recipe>>(
                  stream: _recipeService.getRecipesByAuthor(authorId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text('Error loading recipes: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No recipes found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This user hasn\'t created any recipes yet',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }

                    List<Recipe> userRecipes = snapshot.data!;
                    
                    return Column(
                      children: [
                        // Statistics
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildUserStatItem('Total Recipes', userRecipes.length.toString(), Icons.restaurant),
                              _buildUserStatItem('Public', 
                                userRecipes.where((r) => r.isPublic).length.toString(), Icons.public),
                              _buildUserStatItem('Private', 
                                userRecipes.where((r) => !r.isPublic).length.toString(), Icons.lock),
                              _buildUserStatItem('Avg Rating', 
                                userRecipes.isEmpty ? '0.0' : 
                                (userRecipes.map((r) => r.rating).reduce((a, b) => a + b) / userRecipes.length).toStringAsFixed(1), 
                                Icons.star),
                            ],
                          ),
                        ),
                        // Recipes List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: userRecipes.length,
                            itemBuilder: (context, index) {
                              final recipe = userRecipes[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: _buildRecipeImage(recipe.imageUrl),
                                  title: Text(
                                    recipe.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            recipe.isPublic ? Icons.public : Icons.lock,
                                            size: 14,
                                            color: recipe.isPublic ? Colors.green : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            recipe.isPublic ? 'Public' : 'Private',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: recipe.isPublic ? Colors.green : Colors.orange,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(Icons.star, size: 14, color: Colors.amber),
                                          Text('${recipe.rating}', style: const TextStyle(fontSize: 12)),
                                          const SizedBox(width: 8),
                                          Text(
                                            recipe.createdAt.toString().split(' ')[0],
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      Navigator.pop(context); // Close this dialog first
                                      _handleRecipeAction(value, recipe);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'view_details',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('View Details'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'toggle_visibility',
                                        child: Row(
                                          children: [
                                            Icon(recipe.isPublic ? Icons.lock : Icons.public),
                                            const SizedBox(width: 8),
                                            Text(recipe.isPublic ? 'Make Private' : 'Make Public'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.pop(context); // Close this dialog first
                                    _showRecipeDetails(recipe);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade700),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.blue.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    try {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown Date';
    }
  }

  String _formatIngredient(String ingredient) {
    if (ingredient.isEmpty) return 'No ingredient specified';
    
    // Handle different ingredient formats
    ingredient = ingredient.trim();
    
    // If it looks like structured data (name: xx, unit: xx, amount: xx)
    if (ingredient.contains('name:') && ingredient.contains('unit:') && ingredient.contains('amount:')) {
      try {
        String name = _extractValue(ingredient, 'name');
        String unit = _extractValue(ingredient, 'unit');
        String amount = _extractValue(ingredient, 'amount');
        
        if (name.isNotEmpty) {
          String formattedAmount = amount.isNotEmpty ? amount : '1';
          String formattedUnit = unit.isNotEmpty && unit != '1' ? ' $unit' : '';
          return '$formattedAmount$formattedUnit $name';
        }
      } catch (e) {
        // If parsing fails, return cleaned version
      }
    }
    
    // Return cleaned ingredient
    return ingredient;
  }

  String _formatInstruction(String instruction) {
    if (instruction.isEmpty) return 'No instruction provided';
    
    instruction = instruction.trim();
    
    // Handle video URLs
    if (instruction.startsWith('http') && (instruction.contains('video') || instruction.contains('youtube') || instruction.contains('.mp4'))) {
      return 'Video instruction: ${_shortenUrl(instruction)}';
    }
    
    // Handle structured instruction data
    if (instruction.contains('videoUrl:')) {
      String videoUrl = _extractValue(instruction, 'videoUrl');
      String description = _extractValue(instruction, 'description');
      
      if (description.isNotEmpty) {
        return description + (videoUrl.isNotEmpty ? ' (Video: ${_shortenUrl(videoUrl)})' : '');
      } else if (videoUrl.isNotEmpty) {
        return 'Video instruction: ${_shortenUrl(videoUrl)}';
      }
    }
    
    // Return cleaned instruction
    return instruction;
  }

  String _extractValue(String data, String key) {
    try {
      RegExp regex = RegExp('$key:\\s*([^,}]+)');
      Match? match = regex.firstMatch(data);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return '';
  }

  String _shortenUrl(String url) {
    if (url.length <= 50) return url;
    return '${url.substring(0, 30)}...${url.substring(url.length - 15)}';
  }
} 