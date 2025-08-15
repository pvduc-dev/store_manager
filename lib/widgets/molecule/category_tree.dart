import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/models/category.dart';
import 'package:store_manager/providers/category_provider.dart';

class CategoryTree extends StatefulWidget {
  final Function(Category?) onCategorySelected;
  final Category? selectedCategory;
  final bool showSelectAllOption;

  const CategoryTree({
    Key? key,
    required this.onCategorySelected,
    this.selectedCategory,
    this.showSelectAllOption = true,
  }) : super(key: key);

  @override
  State<CategoryTree> createState() => _CategoryTreeState();
}

class _CategoryTreeState extends State<CategoryTree> {
  Set<int> expandedCategories = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  List<Category> _buildCategoryTree(List<Category> categories) {
    // Tạo danh sách category gốc (parent = 0)
    return categories.where((category) => category.parent == 0).toList();
  }

  List<Category> _getSubCategories(List<Category> categories, int parentId) {
    return categories.where((category) => category.parent == parentId).toList();
  }

  Widget _buildCategoryItem(Category category, List<Category> allCategories, {int level = 0}) {
    final subCategories = _getSubCategories(allCategories, category.id);
    final hasChildren = subCategories.isNotEmpty;
    final isExpanded = expandedCategories.contains(category.id);
    final isSelected = widget.selectedCategory?.id == category.id;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: level * 16.0),
          child: ListTile(
            leading: hasChildren
                ? IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          expandedCategories.remove(category.id);
                        } else {
                          expandedCategories.add(category.id);
                        }
                      });
                    },
                  )
                : Container(
                    width: 48,
                    child: Icon(
                      Icons.category_outlined,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                  ),
            title: Text(
              category.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
            subtitle: category.description.isNotEmpty
                ? Text(
                    category.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                  )
                : null,
            selected: isSelected,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            onTap: () {
              widget.onCategorySelected(category);
            },
          ),
        ),
        if (hasChildren && isExpanded)
          ...subCategories.map((subCategory) =>
              _buildCategoryItem(subCategory, allCategories, level: level + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.categories.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final rootCategories = _buildCategoryTree(categoryProvider.categories);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.category, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Wybierz kategorię produktu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            if (widget.showSelectAllOption)
              ListTile(
                leading: Icon(
                  Icons.all_inclusive,
                  color: Colors.grey[600],
                ),
                title: const Text('Wszystkie kategorie'),
                trailing: widget.selectedCategory == null
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                selected: widget.selectedCategory == null,
                selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                onTap: () {
                  widget.onCategorySelected(null);
                },
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: rootCategories
                    .map((category) => _buildCategoryItem(
                          category,
                          categoryProvider.categories,
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CategorySelector extends StatelessWidget {
  final Function(Category?) onCategorySelected;
  final Category? selectedCategory;
  final String? hintText;

  const CategorySelector({
    Key? key,
    required this.onCategorySelected,
    this.selectedCategory,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: CategoryTree(
              onCategorySelected: (category) {
                onCategorySelected(category);
                Navigator.pop(context);
              },
              selectedCategory: selectedCategory,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.category_outlined,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedCategory?.name ?? hintText ?? 'Wybierz kategorię',
                style: TextStyle(
                  color: selectedCategory != null
                      ? Colors.black87
                      : Colors.grey[600],
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
