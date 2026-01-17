import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

/// Search and color filter bar widget
class SearchFilterBar extends StatelessWidget {
  final String searchQuery;
  final NoteColorTag? selectedColor;
  final Function(String) onSearchChanged;
  final Function(NoteColorTag?) onColorSelected;

  const SearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedColor,
    required this.onSearchChanged,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input
        TextField(
          onChanged: onSearchChanged,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm ghi chú...',
            hintStyle: TextStyle(color: AppTheme.textHint),
            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () => onSearchChanged(''),
                    color: AppTheme.textSecondary,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Label
        Text(
          'Lọc theo màu:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Color filter chips - use Wrap to show all on multiple lines
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: NoteColorTag.values.map((colorTag) {
            return _buildColorChip(colorTag);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorChip(NoteColorTag colorTag) {
    final isSelected = (colorTag == NoteColorTag.none && selectedColor == null) ||
                       (colorTag == selectedColor);
    final color = Color(colorTag.colorValue);
    final lightColor = Color(colorTag.lightColorValue);

    return InkWell(
      onTap: () {
        if (colorTag == NoteColorTag.none) {
          onColorSelected(null); // Clear filter
        } else {
          onColorSelected(colorTag);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : lightColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              colorTag.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
