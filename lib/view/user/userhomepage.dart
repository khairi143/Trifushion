import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login.dart'; // 导入LoginPage
import 'userprofilepage.dart';
import 'searchpage.dart';
import 'myrecipespage.dart';
import '../../view_models/home_view_model.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final List<Widget> _pages = [
    // Home page content will be set in build method
    Container(),
    const SearchPage(),
    const MyRecipesPage(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    _pages[0] = _buildHomeContent();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('iBites'),
        backgroundColor: Colors.transparent,
        actions: [
          // Add logout button to app bar
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),

      //Footer
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildDailyInspiration(),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Categories'),
                _buildCategories(),
              ],
            ),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Latest Recipes', onViewAll: () {}),
                _buildRecipeList(_viewModel.latestRecipes),
              ],
            ),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Recently Viewed', onViewAll: () {}),
                _buildRecipeList(_viewModel.recentlyViewed),
              ],
            ),
          )),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Most Popular', onViewAll: () {}),
                _buildRecipeList(_viewModel.popularRecipes),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDailyInspiration() {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.dailyInspiration.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Inspiration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: PageController(initialPage: viewModel.currentInspirationIndex),
                itemCount: viewModel.dailyInspiration.length,
                onPageChanged: (index) {
                  viewModel.setCurrentInspirationIndex(index);
                },
                itemBuilder: (context, index) {
                  final recipe = viewModel.dailyInspiration[index];
                  return _buildInspirationCard(recipe);
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  viewModel.dailyInspiration.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: viewModel.currentInspirationIndex == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInspirationCard(Recipe recipe) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              recipe.imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecipeList(List<Recipe> recipes) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.asset(
                      recipe.imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                recipe.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'Breakfast', 'icon': Icons.breakfast_dining, 'color': Colors.orange},
      {'name': 'Lunch', 'icon': Icons.lunch_dining, 'color': Colors.green},
      {'name': 'Dinner', 'icon': Icons.dinner_dining, 'color': Colors.purple},
      {'name': 'Dessert', 'icon': Icons.cake, 'color': Colors.pink},
      {'name': 'Snacks', 'icon': Icons.cookie, 'color': Colors.brown},
      {'name': 'Drinks', 'icon': Icons.local_drink, 'color': Colors.blue},
      {'name': 'Vegetarian', 'icon': Icons.eco, 'color': Colors.lightGreen},
      {'name': 'Healthy', 'icon': Icons.favorite, 'color': Colors.red},
    ];

    return SizedBox(
      height: 180, // Fixed height for the grid
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () {
              // TODO: Navigate to category recipes
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category['color'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _authService.signout(); // Sign out the user

                  // Close the dialog
                  Navigator.of(context).pop();

                  // Navigate back to login page and clear history
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                } catch (e) {
                  print("Error during logout: $e");
                  Navigator.of(context).pop(); // Close dialog on error
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error during logout')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
