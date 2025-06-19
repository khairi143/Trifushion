import 'package:flutter/material.dart';

class SmartRecipeFilter extends StatefulWidget {
  final Function(List<String>, List<String>) onFilterChanged;

  const SmartRecipeFilter({
    Key? key,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  _SmartRecipeFilterState createState() => _SmartRecipeFilterState();
}

class _SmartRecipeFilterState extends State<SmartRecipeFilter> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _includedIngredients = [];
  final List<String> _excludedIngredients = [];
  bool _isIncluding = true;

  void _addIngredient(String ingredient) {
    if (ingredient.trim().isEmpty) return;

    setState(() {
      if (_isIncluding) {
        if (!_includedIngredients.contains(ingredient)) {
          _includedIngredients.add(ingredient);
          // Remove from excluded if it was there
          _excludedIngredients.remove(ingredient);
        }
      } else {
        if (!_excludedIngredients.contains(ingredient)) {
          _excludedIngredients.add(ingredient);
          // Remove from included if it was there
          _includedIngredients.remove(ingredient);
        }
      }
      _ingredientController.clear();
    });

    widget.onFilterChanged(_includedIngredients, _excludedIngredients);
  }

  void _removeIngredient(String ingredient, bool fromIncluded) {
    setState(() {
      if (fromIncluded) {
        _includedIngredients.remove(ingredient);
      } else {
        _excludedIngredients.remove(ingredient);
      }
    });

    widget.onFilterChanged(_includedIngredients, _excludedIngredients);
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Type Toggle
          Row(
            children: [
              Expanded(
                child: ToggleButtons(
                  isSelected: [_isIncluding, !_isIncluding],
                  onPressed: (index) {
                    setState(() {
                      _isIncluding = index == 0;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: _isIncluding ? Colors.green : Colors.red,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: 4),
                          Text('Must Include'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline),
                          SizedBox(width: 4),
                          Text('Must Exclude'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Ingredient Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  decoration: InputDecoration(
                    hintText: _isIncluding
                        ? 'Add ingredients you want...'
                        : 'Add ingredients to exclude...',
                    prefixIcon: Icon(
                      _isIncluding ? Icons.add : Icons.remove,
                      color: _isIncluding ? Colors.green : Colors.red,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: _addIngredient,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addIngredient(_ingredientController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIncluding ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Icon(_isIncluding ? Icons.add : Icons.remove),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Selected Ingredients
          if (_includedIngredients.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Must Include:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _includedIngredients.map((ingredient) {
                    return Chip(
                      label: Text(ingredient),
                      backgroundColor: Colors.green[100],
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () => _removeIngredient(ingredient, true),
                    );
                  }).toList(),
                ),
              ],
            ),

          if (_excludedIngredients.isNotEmpty) ...[
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Must Exclude:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _excludedIngredients.map((ingredient) {
                    return Chip(
                      label: Text(ingredient),
                      backgroundColor: Colors.red[100],
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () => _removeIngredient(ingredient, false),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
