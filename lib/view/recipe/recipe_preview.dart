import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:chewie/chewie.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../view_models/recipe_preview.dart';

class RecipePreviewPage extends StatefulWidget {
  final RecipePreviewViewModel viewModel;

  const RecipePreviewPage({Key? key, required this.viewModel})
      : super(key: key);

  @override
  State<RecipePreviewPage> createState() => _RecipePreviewPageState();
}

class _RecipePreviewPageState extends State<RecipePreviewPage> {
  final Map<int, VideoPlayerController?> _previewControllers = {};
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _initPreviewControllers();
  }

  @override
  void dispose() {
    for (final controller in _previewControllers.values) {
      controller?.dispose();
    }
    super.dispose();
  }

  void _initPreviewControllers() async {
    for (var i = 0; i < widget.viewModel.instructions.length; i++) {
      final instruction = widget.viewModel.instructions[i];
      VideoPlayerController? controller;

      final localVideoPath = instruction.localVideoPath as String?;
      final videoUrl = instruction.videoUrl as String?;

      if (kIsWeb) {
        if (localVideoPath != null && localVideoPath.isNotEmpty) {
          // On web, localVideoPath is expected to be a blob URL
          controller =
              VideoPlayerController.networkUrl(Uri.parse(localVideoPath));
        } else if (videoUrl != null && videoUrl.isNotEmpty) {
          controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        }
      } else {
        if (localVideoPath != null && localVideoPath.isNotEmpty) {
          controller = VideoPlayerController.file(File(localVideoPath));
        } else if (videoUrl != null && videoUrl.isNotEmpty) {
          controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
        }
      }

      if (controller != null) {
        await controller.initialize();
        setState(() {
          _previewControllers[i] = controller;
        });
      } else {
        setState(() {
          _previewControllers[i] = null;
        });
      }
    }
  }

  void _pauseAllExcept(int indexToPlay) {
    _previewControllers.forEach((index, controller) {
      if (index == indexToPlay) {
        controller?.play();
        _currentlyPlayingIndex = index;
      } else {
        controller?.pause();
      }
    });
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview Recipe'),
        leading: IconButton(
          icon: Icon(Icons.edit),
          tooltip: 'Back to Edit',
          onPressed: () {
            Navigator.pop(context, viewModel);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (viewModel.coverImage != null &&
                viewModel.coverImage!.path.isNotEmpty)
              kIsWeb
                  ? FutureBuilder<Uint8List>(
                      future: viewModel.coverImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(snapshot.data!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          );
                        } else {
                          return SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                      },
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(viewModel.coverImage!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    ),
            SizedBox(height: 16),
            Text(viewModel.titleController.text,
                style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 8),
            Text(viewModel.descriptionController.text,
                style: Theme.of(context).textTheme.bodyLarge),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.people, size: 20),
                SizedBox(width: 8),
                Text('${viewModel.servingsController.text} servings'),
                SizedBox(width: 16),
                Icon(Icons.timer, size: 20),
                SizedBox(width: 8),
                Text(
                    '${viewModel.prepTimeController.text} min prep + ${viewModel.cookTimeController.text} min cook'),
              ],
            ),
            SizedBox(height: 16),
            if (viewModel.selectedCategories.isNotEmpty) ...[
              Text('Categories',
                  style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: viewModel.selectedCategories
                    .map((category) => Chip(label: Text(category)))
                    .toList(),
              ),
              SizedBox(height: 16),
            ],
            Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: viewModel.ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = viewModel.ingredients[index];
                return ListTile(
                  title: Text(
                      '${ingredient.amount} ${ingredient.unit} ${ingredient.name}'),
                );
              },
            ),
            SizedBox(height: 16),
            Text('Instructions',
                style: Theme.of(context).textTheme.titleMedium),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: viewModel.instructions.length,
              itemBuilder: (context, index) {
                final instruction = viewModel.instructions[index];
                final controller = _previewControllers[index];

                return VisibilityDetector(
                  key: Key('video-$index'),
                  onVisibilityChanged: (info) {
                    final visibleFraction = info.visibleFraction;

                    if (visibleFraction > 0.8) {
                      // This video is mostly visible → play it
                      if (_currentlyPlayingIndex != index) {
                        _pauseAllExcept(index);
                      }
                    } else {
                      // If it was playing but is no longer visible → pause it
                      if (_currentlyPlayingIndex == index) {
                        controller?.pause();
                        _currentlyPlayingIndex = null;
                      }
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                            child: Text('${instruction.stepNumber}')),
                        title: Text(instruction.description),
                      ),
                      controller == null
                          ? Container()
                          : controller.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: controller.value.aspectRatio,
                                  child: Chewie(
                                    controller: ChewieController(
                                      videoPlayerController: controller,
                                      autoPlay:
                                          false, // We control play manually
                                      looping: true,
                                    ),
                                  ))
                              : Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(),
                                ),
                    ],
                  ),
                );
              },
            ),
            if (viewModel.nutritionInfo.calories > 0 ||
                viewModel.nutritionInfo.protein_g > 0 ||
                viewModel.nutritionInfo.carbohydrates_total_g > 0 ||
                viewModel.nutritionInfo.fat_total_g > 0) ...[
              SizedBox(height: 16),
              Text('Nutrition Information',
                  style: Theme.of(context).textTheme.titleMedium),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildNutritionRow('Calories',
                          '${viewModel.nutritionInfo.calories} kcal'),
                      _buildNutritionRow(
                          'Protein', '${viewModel.nutritionInfo.protein_g}g'),
                      _buildNutritionRow('Carbs',
                          '${viewModel.nutritionInfo.carbohydrates_total_g}g'),
                      _buildNutritionRow(
                          'Fat', '${viewModel.nutritionInfo.fat_total_g}g'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
