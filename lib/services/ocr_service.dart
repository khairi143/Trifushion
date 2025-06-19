import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<List<String>> extractTextLines(XFile image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      List<String> lines = [];
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          if (line.text.trim().isNotEmpty) {
            lines.add(line.text.trim());
          }
        }
      }
      
      return lines;
    } catch (e) {
      print('Error extracting text: $e');
      return [];
    }
  }

  RecipeParseResult parseRecipeFromLines(List<String> lines) {
    String title = '';
    String description = '';
    List<String> ingredients = [];
    List<String> instructions = [];
    
    bool isIngredientsSection = false;
    bool isInstructionsSection = false;
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].toLowerCase();
      
      // Try to identify title (usually first meaningful line)
      if (title.isEmpty && line.length > 3 && !_isCommonWord(line)) {
        title = lines[i];
        continue;
      }
      
      // Identify sections
      if (line.contains('ingredient') || line.contains('材料')) {
        isIngredientsSection = true;
        isInstructionsSection = false;
        continue;
      }
      
      if (line.contains('instruction') || line.contains('step') || 
          line.contains('method') || line.contains('做法') || line.contains('步骤')) {
        isInstructionsSection = true;
        isIngredientsSection = false;
        continue;
      }
      
      // Parse ingredients
      if (isIngredientsSection && !isInstructionsSection) {
        if (_looksLikeIngredient(lines[i])) {
          ingredients.add(lines[i]);
        }
      }
      
      // Parse instructions
      if (isInstructionsSection) {
        if (_looksLikeInstruction(lines[i])) {
          instructions.add(lines[i]);
        }
      }
      
      // If no clear sections, try to categorize by content
      if (!isIngredientsSection && !isInstructionsSection) {
        if (_looksLikeIngredient(lines[i])) {
          ingredients.add(lines[i]);
        } else if (_looksLikeInstruction(lines[i])) {
          instructions.add(lines[i]);
        } else if (description.isEmpty && lines[i].length > 10) {
          description = lines[i];
        }
      }
    }
    
    return RecipeParseResult(
      title: title.isNotEmpty ? title : 'Recipe from Image',
      description: description.isNotEmpty ? description : 'Recipe extracted from image',
      ingredients: ingredients,
      instructions: instructions,
    );
  }

  bool _isCommonWord(String text) {
    const commonWords = ['the', 'and', 'or', 'in', 'on', 'at', 'to', 'for', 'of', 'with'];
    return commonWords.any((word) => text.startsWith(word));
  }

  bool _looksLikeIngredient(String text) {
    // Common ingredient patterns
    return text.contains(RegExp(r'\d+.*?(cup|tbsp|tsp|gram|kg|oz|lb|ml|liter)', caseSensitive: false)) ||
           text.contains(RegExp(r'(salt|pepper|sugar|flour|oil|butter|onion|garlic)', caseSensitive: false));
  }

  bool _looksLikeInstruction(String text) {
    // Common instruction patterns
    return text.contains(RegExp(r'^(heat|cook|add|mix|stir|bake|fry|boil|season)', caseSensitive: false)) ||
           text.contains(RegExp(r'\d+\.|\d+\)')) ||
           text.length > 20; // Instructions are usually longer
  }

  void dispose() {
    _textRecognizer.close();
  }
}

class RecipeParseResult {
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;

  RecipeParseResult({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
  });
} 