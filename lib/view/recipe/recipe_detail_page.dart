import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../models/recipe.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import 'recipe_form_page.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final _recipeService = RecipeService();
  ChewieController? _chewieController;
  VideoPlayerController? _videoController;
  int _currentStep = 0;

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadVideo(String? videoUrl) {
    if (videoUrl == null) return;

    _videoController?.dispose();
    _chewieController?.dispose();

    _videoController = VideoPlayerController.network(videoUrl);
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
    );
  }

  void _nextStep() {
    if (_currentStep < widget.recipe.instructions.length - 1) {
      setState(() {
        _currentStep++;
        _loadVideo(widget.recipe.instructions[_currentStep].videoUrl);
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _loadVideo(widget.recipe.instructions[_currentStep].videoUrl);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.read<AuthService>().currentUser?.uid == widget.recipe.userId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Cover Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.recipe.coverImage,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeFormPage(recipe: widget.recipe),
                      ),
                    );
                  },
                ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Recipe'),
                        content: const Text('Are you sure you want to delete this recipe?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await _recipeService.deleteRecipe(
                          widget.recipe.id,
                          widget.recipe.coverImage,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  },
                ),
            ],
          ),

          // Recipe Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Categories
                  Text(
                    widget.recipe.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.recipe.categories.map((category) {
                      return Chip(label: Text(category));
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    widget.recipe.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Time and Servings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn(
                        Icons.timer,
                        'Prep Time',
                        '${widget.recipe.prepTime} min',
                      ),
                      _buildInfoColumn(
                        Icons.restaurant,
                        'Cook Time',
                        '${widget.recipe.cookTime} min',
                      ),
                      _buildInfoColumn(
                        Icons.people,
                        'Servings',
                        widget.recipe.servings.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Nutrition Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nutrition Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildNutritionRow('Calories', '${widget.recipe.nutritionInfo.calories.round()} kcal'),
                          _buildNutritionRow('Protein', '${widget.recipe.nutritionInfo.protein.round()}g'),
                          _buildNutritionRow('Carbs', '${widget.recipe.nutritionInfo.carbs.round()}g'),
                          _buildNutritionRow('Fat', '${widget.recipe.nutritionInfo.fat.round()}g'),
                          _buildNutritionRow('Fiber', '${widget.recipe.nutritionInfo.fiber.round()}g'),
                          _buildNutritionRow('Sugar', '${widget.recipe.nutritionInfo.sugar.round()}g'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ingredients
                  Text(
                    'Ingredients',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.recipe.ingredients.length,
                      itemBuilder: (context, index) {
                        final ingredient = widget.recipe.ingredients[index];
                        return ListTile(
                          title: Text(ingredient.name),
                          subtitle: Text('${ingredient.amount} ${ingredient.unit}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Instructions
                  Text(
                    'Instructions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        // Video Player
                        if (widget.recipe.instructions[_currentStep].videoUrl != null)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Chewie(controller: _chewieController!),
                          ),

                        // Step Navigation
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: _currentStep > 0 ? _previousStep : null,
                              ),
                              Text(
                                'Step ${_currentStep + 1} of ${widget.recipe.instructions.length}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: _currentStep < widget.recipe.instructions.length - 1
                                    ? _nextStep
                                    : null,
                              ),
                            ],
                          ),
                        ),

                        // Step Description
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            widget.recipe.instructions[_currentStep].description,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
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

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
} 