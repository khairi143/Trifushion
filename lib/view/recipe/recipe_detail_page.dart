import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../models/recipe.dart';
import '../../services/auth_service.dart';
import '../../services/recipe_service.dart';
import 'recipe_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);

  @override
  _RecipeDetailPageState createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> with SingleTickerProviderStateMixin {
  final _recipeService = RecipeService();
  ChewieController? _chewieController;
  VideoPlayerController? _videoController;
  int _currentStep = 0;
  late TabController _tabController;
  bool isBookmarked = false;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _checkBookmark();
    if (widget.recipe.instructions.isNotEmpty) {
      _loadVideo(widget.recipe.instructions[0].videoUrl);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _tabController.dispose();
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

  Future<void> _checkBookmark() async {
    if (_currentUserId.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(_currentUserId)
        .collection("bookmarks")
        .doc(widget.recipe.id)
        .get();
    if (mounted) {
      setState(() { isBookmarked = doc.exists; });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please log in to bookmark.")));
      return;
    }
    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(_currentUserId)
        .collection("bookmarks")
        .doc(widget.recipe.id);
    if (isBookmarked) {
      await docRef.delete();
    } else {
      await docRef.set({ "recipeId": widget.recipe.id, "savedAt": FieldValue.serverTimestamp() });
    }
    if (mounted) {
      setState(() { isBookmarked = !isBookmarked; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.read<AuthService>().currentUser?.uid == widget.recipe.userId;
    final authorEmail = widget.recipe.userId.isNotEmpty ? widget.recipe.userId : '-';
    final recipe = widget.recipe;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Cover Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.network(
              recipe.coverImage.isNotEmpty ? recipe.coverImage : 'https://via.placeholder.com/400x300?text=No+Image',
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Bookmark button
          Positioned(
            top: 40,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.redAccent),
                onPressed: _toggleBookmark,
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
                padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 24),
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe.description.isNotEmpty ? recipe.description : '-',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Time, Difficulty, Calories
                    Row(
                      children: [
                        Icon(Icons.timer, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text('${recipe.prepTime > 0 ? recipe.prepTime : '-'} Min'),
                        const SizedBox(width: 16),
                        Icon(Icons.local_fire_department, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text('${recipe.nutritionInfo.calories > 0 ? recipe.nutritionInfo.calories.round() : '-'} Cal'),
                        const SizedBox(width: 16),
                        Icon(Icons.signal_cellular_alt, size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(recipe.categories.isNotEmpty ? recipe.categories.first : '-'),
                      ],
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
                              (recipe.createdByName.isNotEmpty ? recipe.createdByName : (recipe.userId.isNotEmpty ? recipe.userId : '-')),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Recipe Author', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                          child: Text('+ Follow'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Tab Bar
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.redAccent,
                      ),
                      tabs: const [
                        Tab(text: 'Ingredients'),
                        Tab(text: 'Instructions'),
                        Tab(text: 'Review'),
                      ],
                    ),
                    SizedBox(
                      height: 320,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Ingredients Tab
                          recipe.ingredients.isNotEmpty
                              ? ListView.separated(
                                  itemCount: recipe.ingredients.length,
                                  separatorBuilder: (context, i) => Divider(),
                                  itemBuilder: (context, i) {
                                    final ing = recipe.ingredients[i];
                                    return ListTile(
                                      leading: Text('${i + 1}'.padLeft(2, '0')),
                                      title: Text(ing.name.isNotEmpty ? ing.name : '-'),
                                      subtitle: Text(
                                        (ing.amount > 0 ? ing.amount.toString() : '-') +
                                            (ing.unit.isNotEmpty ? ' ${ing.unit}' : ''),
                                      ),
                                    );
                                  },
                                )
                              : Center(child: Text('No ingredients.')),
                          // Instructions Tab
                          recipe.instructions.isNotEmpty
                              ? ListView.separated(
                                  itemCount: recipe.instructions.length,
                                  separatorBuilder: (context, i) => Divider(),
                                  itemBuilder: (context, i) {
                                    final step = recipe.instructions[i];
                                    return ExpansionTile(
                                      leading: Text('${i + 1}'.padLeft(2, '0')),
                                      title: Text(step.description.isNotEmpty ? step.description : '-'),
                                      children: [
                                        if (step.videoUrl != null && step.videoUrl!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: AspectRatio(
                                              aspectRatio: 16 / 9,
                                              child: Chewie(
                                                controller: ChewieController(
                                                  videoPlayerController: VideoPlayerController.network(step.videoUrl!),
                                                  autoPlay: false,
                                                  looping: false,
                                                  aspectRatio: 16 / 9,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (step.duration != null)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Duration: ${step.duration} seconds'),
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
  }
} 