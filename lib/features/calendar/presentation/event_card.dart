import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/calendar_event.dart';

/// A card widget displaying a single calendar event with status indicators.
///
/// Shows the event time range, title, and a trailing status indicator that
/// changes based on event status (upcoming, in_progress, ended, reflected,
/// skipped). Supports swipe-to-skip via [Dismissible] and tap actions.
class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onSkip;
  final String? reflectionPreview;
  final VoidCallback? onReflectionTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onSkip,
    this.reflectionPreview,
    this.onReflectionTap,
  });

  /// Returns the left border color based on event status.
  Color _borderColor(ColorScheme colorScheme) {
    switch (event.status) {
      case 'in_progress':
        return colorScheme.primary;
      case 'ended':
        return Colors.orange;
      case 'reflected':
        return Colors.green;
      case 'skipped':
        return Colors.grey;
      default: // upcoming
        return colorScheme.outlineVariant;
    }
  }

  /// Builds the trailing status indicator widget.
  Widget _buildStatusIndicator(ThemeData theme, ColorScheme colorScheme) {
    switch (event.status) {
      case 'upcoming':
        return Icon(
          Icons.schedule,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        );
      case 'in_progress':
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary,
          ),
        );
      case 'ended':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Needs reflection',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'reflected':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 18, color: Colors.green),
            if (reflectionPreview != null) ...[
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  reflectionPreview!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        );
      case 'skipped':
        return Text(
          'Skipped',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withAlpha(128),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Formats the event time range (e.g., "9:00 AM - 10:00 AM").
  String _formatTimeRange() {
    if (event.isAllDay) return 'All day';
    final formatter = DateFormat.jm();
    return '${formatter.format(event.startAt)} - ${formatter.format(event.endAt)}';
  }

  void _handleTap() {
    if (event.status == 'reflected') {
      onReflectionTap?.call();
    } else if (event.status != 'skipped') {
      onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSkipped = event.status == 'skipped';

    Widget card = Opacity(
      opacity: isSkipped ? 0.5 : 1.0,
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _borderColor(colorScheme),
                width: 3,
              ),
            ),
          ),
          child: InkWell(
            onTap: isSkipped ? null : _handleTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Time range on the left
                  SizedBox(
                    width: 90,
                    child: Text(
                      _formatTimeRange(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title in center
                  Expanded(
                    child: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status indicator on right
                  _buildStatusIndicator(theme, colorScheme),
                  // Skip button for ended events
                  if (event.status == 'ended' && onSkip != null) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        onPressed: onSkip,
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.zero,
                        tooltip: 'Skip reflection',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Wrap in Dismissible for swipe-to-skip (only for actionable statuses)
    if (event.status == 'ended' || event.status == 'upcoming' || event.status == 'in_progress') {
      card = Dismissible(
        key: ValueKey('event-dismiss-${event.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async => true,
        onDismissed: (_) => onSkip?.call(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Skip',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: card,
      );
    }

    return card;
  }
}
