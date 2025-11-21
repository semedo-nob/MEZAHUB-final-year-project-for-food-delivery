import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/category.dart';
import '../theme/app_colors.dart';
import '../provider/menu_provider.dart';

class CategoryBodyPage extends StatefulWidget {
  const CategoryBodyPage({super.key});

  @override
  State<CategoryBodyPage> createState() => _CategoryBodyPageState();
}

class _CategoryBodyPageState extends State<CategoryBodyPage> {
  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final categoriesWithCounts = menuProvider.getCategoriesWithCounts();

    return Container(
      height: 110, // Increased height to accommodate the content
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Reduced vertical padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoriesWithCounts.length,
        itemBuilder: (context, index) {
          final categoryData = categoriesWithCounts[index];
          final category = categoryData['category'] as Category;
          final itemCount = categoryData['itemCount'] as int;
          final isSelected = menuProvider.selectedCategoryId == category.id;

          return _buildCategoryItem(context, category, itemCount, isSelected, menuProvider);
        },
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, Category category, int itemCount, bool isSelected, MenuProvider menuProvider) {
    return GestureDetector(
      onTap: () => _onCategoryTap(category, isSelected, menuProvider),
      child: Container(
        width: 75, // Slightly reduced width
        margin: const EdgeInsets.symmetric(horizontal: 6), // Reduced margin
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Changed to start
          mainAxisSize: MainAxisSize.min, // Important: use min to avoid overflow
          children: [
            // Icon container
            Container(
              height: 50, // Fixed height for icon container
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(10), // Reduced padding
                decoration: BoxDecoration(
                  color: isSelected ? category.color : category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? category.color : category.color.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: category.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: Center( // Center the icon
                  child: Text(
                    category.icon,
                    style: TextStyle(
                      fontSize: 20, // Reduced font size
                      color: isSelected ? Colors.white : category.color,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Category name
            Text(
              category.name,
              style: TextStyle(
                fontSize: 11, // Reduced font size
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? category.color : Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Item count
            Text(
              '($itemCount)',
              style: TextStyle(
                fontSize: 9, // Reduced font size
                color: isSelected ? category.color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCategoryTap(Category category, bool isSelected, MenuProvider menuProvider) {
    if (isSelected) {
      // Deselect if already selected
      menuProvider.filterByCategory(null);
    } else {
      // Select new category
      menuProvider.filterByCategory(category.id);
    }
  }
}