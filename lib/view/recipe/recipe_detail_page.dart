import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import '../../models/recipe.dart';
import '../../view_models/recipe_detail_page_vm.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with SingleTickerProviderStateMixin {
  late RecipeDetailViewModel viewModel;
  bool _showTimeDetails = false;
  bool _showNutritionDetails = false;

  @override
  void initState() {
    super.initState();
    viewModel = RecipeDetailViewModel(
      recipe: widget.recipe,
      vsync: this, // Only pass this ONCE
    );
    viewModel.initPreviewControllers(this);
  }

  @override
  void dispose() {
    viewModel.disposeControllers();
    viewModel.tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const iconSize = 18.0;
    final Color? iconColor = Colors.grey[700];
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<RecipeDetailViewModel>(
        builder: (context, vm, _) {
          final recipe = vm.recipe;
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              title: Text(recipe.title),
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                tooltip: 'Back to Listing',
                onPressed: () {
                  Navigator.pop(context, vm);
                },
              ),
            ),
            body: Stack(
              children: [
                // Cover Image
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Image.network(
                    recipe.coverImage.isNotEmpty
                        ? recipe.coverImage
                        : 'https://via.placeholder.com/400x300?text=No+Image',
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Bookmark button (logic can be moved to ViewModel)
                Positioned(
                  top: 40,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(
                          vm.isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Colors.redAccent),
                      onPressed: () {
                        vm.toggleBookmark(context);
                      },
                    ),
                  ),
                ),
                // Main Card
                Positioned(
                  top: 220,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      padding: const EdgeInsets.only(
                          top: 40, left: 24, right: 24, bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Description
                          Text(
                            recipe.title.isNotEmpty ? recipe.title : '-',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recipe.description.isNotEmpty
                                ? recipe.description
                                : '-',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          // Time, Difficulty, Calories
                          Row(
                            children: [
                              // Servings
                              Icon(Icons.people,
                                  size: iconSize, color: iconColor),
                              const SizedBox(width: 4),
                              Text(
                                  '${recipe.servings > 0 ? recipe.servings : '-'} Servings'),
                              const SizedBox(width: 16),

                              // Total Time (expandable)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _showTimeDetails = !_showTimeDetails;
                                    _showNutritionDetails = false;
                                  }),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: iconSize, color: iconColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(recipe.prepTime + recipe.cookTime) > 0 ? (recipe.prepTime + recipe.cookTime) : '-'} Min Total',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(
                                        _showTimeDetails
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Calories (expandable)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _showNutritionDetails =
                                        !_showNutritionDetails;
                                    _showTimeDetails = false;
                                  }),
                                  child: Row(
                                    children: [
                                      Icon(Icons.local_fire_department,
                                          size: iconSize, color: iconColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${recipe.nutritionInfo.calories > 0 ? recipe.nutritionInfo.calories.round() : '-'} Cal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Icon(
                                        _showNutritionDetails
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Categories
                              Icon(Icons.signal_cellular_alt,
                                  size: iconSize, color: iconColor),
                              const SizedBox(width: 4),
                              Text(recipe.categories.isNotEmpty
                                  ? recipe.categories.first
                                  : '-'),
                            ],
                          ),
                          // Expanded Time Details
                          if (_showTimeDetails)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 32, top: 4, bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.timer, size: 16, color: iconColor),
                                  const SizedBox(width: 4),
                                  Text(
                                      'Prep: ${recipe.prepTime > 0 ? recipe.prepTime : '-'} min'),
                                  const SizedBox(width: 16),
                                  Icon(Icons.timer_outlined,
                                      size: 16, color: iconColor),
                                  const SizedBox(width: 4),
                                  Text(
                                      'Cook: ${recipe.cookTime > 0 ? recipe.cookTime : '-'} min'),
                                ],
                              ),
                            ),
                          // Expanded Nutrition Details
                          if (_showNutritionDetails)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 32, top: 4, bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.fastfood,
                                      size: 16, color: iconColor),
                                  const SizedBox(width: 4),
                                  Text(
                                      'Carbs: ${recipe.nutritionInfo.carbs > 0 ? recipe.nutritionInfo.carbs.round() : '-'} g'),
                                  const SizedBox(width: 16),
                                  Icon(Icons.local_dining,
                                      size: 16, color: iconColor),
                                  const SizedBox(width: 4),
                                  Text(
                                      'Protein: ${recipe.nutritionInfo.protein > 0 ? recipe.nutritionInfo.protein.round() : '-'} g'),
                                  const SizedBox(width: 16),
                                  Icon(Icons.restaurant,
                                      size: 16, color: iconColor),
                                  const SizedBox(width: 4),
                                  Text(
                                      'Fat: ${recipe.nutritionInfo.fat > 0 ? recipe.nutritionInfo.fat.round() : '-'} g'),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),
                          // Author
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (recipe.createdByName.isNotEmpty
                                        ? recipe.createdByName
                                        : (recipe.userId.isNotEmpty
                                            ? recipe.userId
                                            : '-')),
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Recipe Author',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12)),
                                ],
                              ),
                              Spacer(),
                              // hide when recipe owner is the current user
                              if (recipe.userId != vm.currentUserId)
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(24)),
                                    elevation: 0,
                                  ),
                                  child: Text('+ Follow'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Tab Bar
                          TabBar(
                            controller: vm.tabController,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.black,
                            indicator: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(24), // Less rounded
                              color: const Color.fromARGB(255, 255, 57, 57),
                            ),
                            indicatorPadding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            indicatorSize: TabBarIndicatorSize.tab,
                            tabs: const [
                              Tab(text: 'Ingredients'),
                              Tab(text: 'Instructions'),
                              Tab(text: 'Review'),
                            ],
                          ),
                          SizedBox(
                            height: 320,
                            child: TabBarView(
                              controller: vm.tabController,
                              children: [
                                // Ingredients Tab
                                recipe.ingredients.isNotEmpty
                                    ? ListView.separated(
                                        itemCount: recipe.ingredients.length,
                                        separatorBuilder: (context, i) =>
                                            Divider(),
                                        itemBuilder: (context, i) {
                                          final ing = recipe.ingredients[i];
                                          return ListTile(
                                            leading: Text(
                                                '${i + 1}'.padLeft(2, '0')),
                                            title: Text(ing.name.isNotEmpty
                                                ? ing.name
                                                : '-'),
                                            subtitle: Text(
                                              (ing.amount > 0
                                                      ? ing.amount.toString()
                                                      : '-') +
                                                  (ing.unit.isNotEmpty
                                                      ? ' ${ing.unit}'
                                                      : ''),
                                            ),
                                          );
                                        },
                                      )
                                    : Center(child: Text('No ingredients.')),
                                // Instructions Tab
                                recipe.instructions.isNotEmpty
                                    ? ListView.separated(
                                        itemCount: recipe.instructions.length,
                                        separatorBuilder: (context, i) =>
                                            Divider(),
                                        itemBuilder: (context, i) {
                                          final step = recipe.instructions[i];
                                          final controller =
                                              vm.previewControllers[i];
                                          return ExpansionTile(
                                            leading: Text(
                                                '${i + 1}'.padLeft(2, '0')),
                                            title: Text(
                                                step.description.isNotEmpty
                                                    ? step.description
                                                    : '-'),
                                            children: [
                                              if (controller != null &&
                                                  controller
                                                      .value.isInitialized)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: AspectRatio(
                                                    aspectRatio: controller
                                                        .value.aspectRatio,
                                                    child: Chewie(
                                                      controller:
                                                          ChewieController(
                                                        videoPlayerController:
                                                            controller,
                                                        autoPlay: false,
                                                        looping: false,
                                                        aspectRatio: 16 / 9,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (step.duration != null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                      'Duration: ${step.duration} seconds'),
                                                ),
                                            ],
                                          );
                                        },
                                      )
                                    : Center(child: Text('No instructions.')),
                                // Review Tab
                                Center(child: Text('No reviews yet.')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Back Button
                Positioned(
                  top: 40,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
