import 'package:flutter/material.dart';
import '../../models/vod.dart';

/// 筛选面板
class FilterPanel extends StatefulWidget {
  final List<Filter> filters;
  final Map<String, String> selectedFilters;
  final Function(Map<String, String>) onApply;
  final VoidCallback onClose;

  const FilterPanel({
    super.key,
    required this.filters,
    required this.selectedFilters,
    required this.onApply,
    required this.onClose,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late Map<String, String> _tempSelectedFilters;

  @override
  void initState() {
    super.initState();
    _tempSelectedFilters = Map.from(widget.selectedFilters);
  }

  void _onFilterSelected(String filterKey, String value) {
    setState(() {
      if (value.isEmpty) {
        _tempSelectedFilters.remove(filterKey);
      } else {
        _tempSelectedFilters[filterKey] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          width: 300,
          height: double.infinity,
          color: Theme.of(context).cardColor,
          child: Column(
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '筛选',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
              
              // 筛选条件列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.filters.length,
                  itemBuilder: (context, index) {
                    final filter = widget.filters[index];
                    return _buildFilterSection(filter);
                  },
                ),
              ),
              
              // 按钮栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[800]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _tempSelectedFilters.clear();
                          });
                        },
                        child: const Text('重置'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(_tempSelectedFilters);
                        },
                        child: const Text('确定'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(Filter filter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filter.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filter.value.map((value) {
              final isSelected = _tempSelectedFilters[filter.key] == value.v;
              
              return ChoiceChip(
                label: Text(value.n),
                selected: isSelected,
                onSelected: (selected) {
                  _onFilterSelected(
                    filter.key,
                    selected ? value.v : '',
                  );
                },
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
