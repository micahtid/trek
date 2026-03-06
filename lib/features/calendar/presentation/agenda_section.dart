import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../shell/app_shell.dart';
import '../../today/domain/entry.dart';
import '../../today/presentation/compose_sheet.dart';
import '../../today/presentation/entry_detail_screen.dart';
import '../../today/presentation/entry_providers.dart';
import '../data/calendar_event_repository.dart';
import '../domain/calendar_event.dart';
import 'calendar_providers.dart';
import 'event_card.dart';

/// Collapsible agenda section showing today's calendar events and missed
/// events from past days.
///
/// Sits at the top of [TodayScreen]. Watches [todayCalendarEventsProvider]
/// for today's events and [unreflectedEventsProvider] for catch-up events.
/// Renders nothing when both providers return empty lists (Calendar not
/// connected or no events).
class AgendaSection extends ConsumerStatefulWidget {
  /// Optional event ID to highlight (from deep-link navigation).
  final String? highlightEventId;

  const AgendaSection({super.key, this.highlightEventId});

  @override
  ConsumerState<AgendaSection> createState() => _AgendaSectionState();
}

class _AgendaSectionState extends ConsumerState<AgendaSection> {
  bool _isExpanded = true;

  /// Tracks event IDs that have been dismissed/skipped locally but haven't
  /// yet been reflected in the provider data. Prevents the "dismissed
  /// Dismissible still in tree" error.
  final Set<String> _dismissedEventIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.highlightEventId != null) {
      _isExpanded = true;
    }
  }

  /// Opens the ComposeSheet pre-linked to a calendar event.
  void _openComposeForEvent(CalendarEvent event) {
    ref.read(fabVisibleProvider.notifier).hide();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ComposeSheet(
        calendarEventId: event.id,
        eventTitle: event.title,
      ),
    ).whenComplete(() {
      ref.read(fabVisibleProvider.notifier).show();
    });
  }

  /// Skips a calendar event with undo support.
  ///
  /// Immediately removes the event from the visible list, then fires the
  /// API call. Shows a SnackBar with an Undo action that reverts the skip.
  Future<void> _skipEvent(CalendarEvent event) async {
    // Remove from visible list immediately (fixes Dismissible tree error)
    setState(() => _dismissedEventIds.add(event.id));

    final eventRepo = ref.read(calendarEventRepositoryProvider);

    // Show undo snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Skipped "${event.title}"'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              // Re-show the event in the list
              setState(() => _dismissedEventIds.remove(event.id));
              // Revert status to ended
              await eventRepo.updateEventStatus(
                eventId: event.id,
                status: 'ended',
              );
              ref.invalidate(todayCalendarEventsProvider);
              ref.invalidate(unreflectedEventsProvider);
            },
          ),
        ),
      );
    }

    // Fire the actual skip API call
    await eventRepo.updateEventStatus(
      eventId: event.id,
      status: 'skipped',
    );
    ref.invalidate(todayCalendarEventsProvider);
    ref.invalidate(unreflectedEventsProvider);
  }

  /// Navigates to the linked entry detail for a reflected event.
  void _openLinkedEntry(CalendarEvent event, List<Entry> todayEntries) {
    final linkedEntry = todayEntries
        .where((e) => e.calendarEventId == event.id)
        .firstOrNull;

    if (linkedEntry != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntryDetailScreen(entry: linkedEntry),
        ),
      );
    }
  }

  /// Groups missed events by date and returns date-labeled sections.
  Map<DateTime, List<CalendarEvent>> _groupByDate(List<CalendarEvent> events) {
    final grouped = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final date = DateTime(
        event.startAt.year,
        event.startAt.month,
        event.startAt.day,
      );
      grouped.putIfAbsent(date, () => []).add(event);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final todayEventsAsync = ref.watch(todayCalendarEventsProvider);
    final unreflectedAsync = ref.watch(unreflectedEventsProvider);

    // Also trigger notification scheduling
    ref.watch(calendarNotificationSchedulerProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get today's entries for finding reflection previews
    final todayEntries = ref.watch(todayEntriesProvider).asData?.value ?? [];

    return todayEventsAsync.when(
      loading: () => _buildLoadingHeader(theme, colorScheme),
      error: (error, _) => _buildErrorState(theme, colorScheme),
      data: (todayEvents) {
        final unreflectedEvents = unreflectedAsync.asData?.value ?? [];

        // Filter unreflected events to only those NOT from today
        final today = DateTime.now();
        final startOfToday = DateTime(today.year, today.month, today.day);
        final missedEvents = unreflectedEvents.where((e) {
          final eventDate = DateTime(
            e.startAt.year,
            e.startAt.month,
            e.startAt.day,
          );
          return eventDate.isBefore(startOfToday);
        }).toList();

        // Filter out locally dismissed events
        final visibleTodayEvents = todayEvents
            .where((e) => !_dismissedEventIds.contains(e.id))
            .toList();
        final visibleMissedEvents = missedEvents
            .where((e) => !_dismissedEventIds.contains(e.id))
            .toList();

        // If no events at all, render nothing
        if (visibleTodayEvents.isEmpty && visibleMissedEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            _buildHeader(theme, colorScheme, visibleTodayEvents.length),

            // Expandable content
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Today's events
                        if (visibleTodayEvents.isNotEmpty) ...[
                          ..._buildTodayEvents(
                            visibleTodayEvents,
                            todayEntries,
                            theme,
                            colorScheme,
                          ),
                        ],

                        // Missed events from past days
                        if (visibleMissedEvents.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ..._buildMissedEvents(
                            visibleMissedEvents,
                            todayEntries,
                            theme,
                            colorScheme,
                          ),
                        ],

                        const SizedBox(height: 8),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Divider between agenda and entries
            if (visibleTodayEvents.isNotEmpty || visibleMissedEvents.isNotEmpty)
              const Divider(height: 1),
          ],
        );
      },
    );
  }

  /// Header row with title, event count badge, and expand/collapse chevron.
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, int eventCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          Text(
            "Today's Meetings",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (eventCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$eventCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: AnimatedRotation(
              turns: _isExpanded ? 0.25 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.chevron_right, size: 20),
            ),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            tooltip: _isExpanded ? 'Collapse' : 'Expand',
          ),
        ],
      ),
    );
  }

  /// Builds the list of today's event cards.
  List<Widget> _buildTodayEvents(
    List<CalendarEvent> events,
    List<Entry> todayEntries,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Sort by start time ascending
    final sorted = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return sorted.map((event) {
      final isHighlighted = widget.highlightEventId == event.id;
      final preview = _getReflectionPreview(event, todayEntries);

      Widget card = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: EventCard(
          event: event,
          onTap: () => _openComposeForEvent(event),
          onSkip: () => _skipEvent(event),
          reflectionPreview: preview,
          onReflectionTap: () => _openLinkedEntry(event, todayEntries),
        ),
      );

      // Highlight the deep-linked event with amber background
      if (isHighlighted) {
        card = Container(
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: card,
        );
      }

      return card;
    }).toList();
  }

  /// Builds missed events grouped by date with section headers.
  List<Widget> _buildMissedEvents(
    List<CalendarEvent> missedEvents,
    List<Entry> todayEntries,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final grouped = _groupByDate(missedEvents);
    // Sort dates descending (most recent first)
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final widgets = <Widget>[];

    for (final date in sortedDates) {
      final dateEvents = grouped[date]!
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      // Date header
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            DateFormat.yMMMMEEEEd().format(date),
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

      // Event cards for this date
      for (final event in dateEvents) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: EventCard(
              event: event,
              onTap: () => _openComposeForEvent(event),
              onSkip: () => _skipEvent(event),
              reflectionPreview:
                  _getReflectionPreview(event, todayEntries),
              onReflectionTap: () =>
                  _openLinkedEntry(event, todayEntries),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Gets the reflection preview text for a reflected event.
  String? _getReflectionPreview(
    CalendarEvent event,
    List<Entry> todayEntries,
  ) {
    if (!event.isReflected) return null;
    final linkedEntry = todayEntries
        .where((e) => e.calendarEventId == event.id)
        .firstOrNull;
    return linkedEntry?.body;
  }

  /// Loading state: header with a linear progress indicator.
  Widget _buildLoadingHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme, colorScheme, 0),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Error state: subtle message with retry button.
  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme, colorScheme, 0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Could not load calendar',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(todayCalendarEventsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
