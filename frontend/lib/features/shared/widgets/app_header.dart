import 'package:flutter/material.dart';

class ReusableFilterHeader extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilterChanged; 
  final bool enableSearch;
  final List<String> filterFields; // ví dụ: ["category", "status"]
  final Map<String, List<String>> filterOptions; 
  // ví dụ: {"category": ["Tivi", "Laptop"], "status": ["Approved", "Pending"]}

  const ReusableFilterHeader({
    Key? key,
    required this.onFilterChanged,
    this.enableSearch = true,
    this.filterFields = const [],
    this.filterOptions = const {},
  }) : super(key: key);

  @override
  State<ReusableFilterHeader> createState() => _ReusableFilterHeaderState();
}

class _ReusableFilterHeaderState extends State<ReusableFilterHeader> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, String?> selectedFilters = {};

  void _applyFilters() {
    final filters = <String, dynamic>{};
    if (widget.enableSearch && _searchController.text.isNotEmpty) {
      filters["search"] = _searchController.text;
    }
    selectedFilters.forEach((key, value) {
      if (value != null) {
        filters[key] = value;
      }
    });
    widget.onFilterChanged(filters);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.enableSearch)
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: "Tìm kiếm",
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _applyFilters,
              ),
            ),
            onSubmitted: (_) => _applyFilters(),
          ),
        Wrap(
          spacing: 10,
          children: widget.filterFields.map((field) {
            return DropdownButton<String>(
              hint: Text(field),
              value: selectedFilters[field],
              items: widget.filterOptions[field]
                      ?.map((option) =>
                          DropdownMenuItem(value: option, child: Text(option)))
                      .toList() ??
                  [],
              onChanged: (value) {
                setState(() {
                  selectedFilters[field] = value;
                });
                _applyFilters();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
