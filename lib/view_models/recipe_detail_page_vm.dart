import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe.dart';

class RecipeDetailViewModel extends ChangeNotifier {
  final Recipe recipe;
  late TabController tabController;
  ChewieController? chewieController;
  VideoPlayerController? videoController;
  int currentStep = 0;
  bool isBookmarked = false;
  late String currentUserId;
  final TickerProvider tickerProvider;

  RecipeDetailViewModel({
    required this.recipe,
    required this.tickerProvider,
  }) {
    tabController = TabController(length: 3, vsync: tickerProvider);
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    checkBookmark();
    if (recipe.instructions.isNotEmpty) {
      loadVideo(recipe.instructions[0].videoUrl);
    }
  }

  void disposeControllers() {
    chewieController?.dispose();
    videoController?.dispose();
    tabController.dispose();
  }

  void loadVideo(String? videoUrl) {
    if (videoUrl == null) return;
    videoController?.dispose();
    chewieController?.dispose();
    videoController = VideoPlayerController.network(videoUrl);
    chewieController = ChewieController(
      videoPlayerController: videoController!,
      autoPlay: false,
      looping: false,
      aspectRatio: 16 / 9,
    );
    notifyListeners();
  }

  void nextStep() {
    if (currentStep < recipe.instructions.length - 1) {
      currentStep++;
      loadVideo(recipe.instructions[currentStep].videoUrl);
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      loadVideo(recipe.instructions[currentStep].videoUrl);
      notifyListeners();
    }
  }

  Future<void> checkBookmark() async {
    if (currentUserId.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("bookmarks")
        .doc(recipe.id)
        .get();
    isBookmarked = doc.exists;
    notifyListeners();
  }

  Future<void> toggleBookmark(BuildContext context) async {
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please log in to bookmark.")));
      return;
    }
    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("bookmarks")
        .doc(recipe.id);
    if (isBookmarked) {
      await docRef.delete();
    } else {
      await docRef.set(
          {"recipeId": recipe.id, "savedAt": FieldValue.serverTimestamp()});
    }
    isBookmarked = !isBookmarked;
    notifyListeners();
  }
}
