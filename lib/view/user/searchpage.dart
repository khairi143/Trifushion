import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });
    // TODO: Implement actual search functionality
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
            ),
          ),

          // Search Results
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : _buildSearchSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // TODO: Replace with actual search results
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Placeholder count
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/fruit_parfait.jpg',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text('Recipe ${index + 1}'),
            subtitle: Text('Description for recipe ${index + 1}'),
            trailing: IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                // TODO: Save recipe
              },
            ),
            onTap: () {
              // TODO: Navigate to recipe details
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Popular Searches',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSuggestionChip('Healthy'),
            _buildSuggestionChip('Vegetarian'),
            _buildSuggestionChip('Quick Meals'),
            _buildSuggestionChip('Low Carb'),
            _buildSuggestionChip('Breakfast'),
            _buildSuggestionChip('Desserts'),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Recent Searches',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // TODO: Replace with actual recent searches
        _buildRecentSearchItem('Pasta Recipes'),
        _buildRecentSearchItem('Chicken Curry'),
        _buildRecentSearchItem('Salad Ideas'),
      ],
    );
  }

  Widget _buildSuggestionChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _performSearch(label);
      },
    );
  }

  Widget _buildRecentSearchItem(String query) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(query),
      onTap: () {
        _searchController.text = query;
        _performSearch(query);
      },
    );
  }
} 