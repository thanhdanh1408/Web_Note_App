import 'package:flutter/material.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

/// Card widget to display note in list
class NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTag = note.colorTag;
    final tagColor = Color(colorTag.colorValue);
    final lightColor = Color(colorTag.lightColorValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? lightColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? tagColor : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected 
                      ? tagColor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: isSelected ? 12 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Color indicator
                    if (colorTag != NoteColorTag.none)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    
                    // Title
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Ghi chú không tiêu đề' : note.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelected ? tagColor : AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Pin icon
                    if (note.isPinned)
                      Icon(
                        Icons.push_pin_rounded,
                        size: 16,
                        color: AppTheme.accentYellow,
                      ),
                    
                    // Private icon
                    if (note.isPrivate)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Preview
                Text(
                  note.preview,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 10),
                
                // Footer with timestamp
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(note.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
