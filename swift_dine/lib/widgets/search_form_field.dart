import 'package:flutter/material.dart';

class SearchFormField extends StatelessWidget {
  final TextEditingController? controller;
  final IconData icon;
  final VoidCallback onFilter;

  const SearchFormField({
    super.key,
    this.controller,
    required this.icon,
    required this.onFilter, required Null Function(dynamic value) onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search restaurants or dishes...',
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: onFilter,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onSubmitted: (value) => onFilter(), // Trigger search when pressing enter
    );
  }
}
