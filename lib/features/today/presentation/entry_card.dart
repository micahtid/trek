import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/entry.dart';

/// A card widget that displays a preview of a Daily Canvas [Entry].
///
/// Shows 2-3 lines of body text, a formatted timestamp, and a mic badge
/// if the entry was created via voice input. Tapping the card triggers
/// the [onTap] callback (typically navigates to [EntryDetailScreen]).
class EntryCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onTap;

  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  /// Formats the creation timestamp.
  ///
  /// If the entry was created today, shows just the time (e.g., "2:30 PM").
  /// Otherwise, shows the date and time (e.g., "Mar 3, 2:30 PM").
  String _formatTimestamp(DateTime createdAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (entryDay == today) {
      return DateFormat.jm().format(createdAt); // e.g., "2:30 PM"
    }
    return DateFormat.MMMd().add_jm().format(createdAt); // e.g., "Mar 3, 2:30 PM"
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Body text preview — 3 lines max
              Text(
                entry.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              // Bottom row: timestamp + optional mic badge
              Row(
                children: [
                  if (entry.isVoice) ...[
                    Icon(
                      Icons.mic,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.withAlpha(153),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _formatTimestamp(entry.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
