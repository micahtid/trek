import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../calendar/domain/calendar_event.dart';
import '../calendar/presentation/agenda_section.dart';
import '../calendar/presentation/calendar_providers.dart';
import 'domain/entry.dart';
import 'presentation/entry_card.dart';
import 'presentation/entry_detail_screen.dart';
import 'presentation/entry_providers.dart';
import 'presentation/search_screen.dart';

/// The daily canvas — a card-stream feed showing today's reflection entries.
///
/// Watches [todayEntriesProvider] for real-time updates and displays
/// [EntryCard] widgets in reverse chronological order (newest first).
/// A FAB opens the [ComposeSheet] for creating new entries.
///
/// Shows an [AgendaSection] at the top when Calendar is connected, displaying
/// today's meetings and missed events from past days.
///
/// Supports pull-to-refresh to reload both entries and calendar events.
class TodayScreen extends ConsumerWidget {
  /// Optional event ID to highlight (from notification deep-link).
  final String? highlightEventId;

  const TodayScreen({super.key, this.highlightEventId});

  void _openEntryDetail(BuildContext context, Entry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntryDetailScreen(entry: entry),
      ),
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(todayEntriesProvider);
    ref.invalidate(todayCalendarEventsProvider);
    ref.invalidate(unreflectedEventsProvider);
    // Wait for both to complete so the refresh indicator stays visible
    await Future.wait([
      ref.read(todayEntriesProvider.future),
      ref.read(todayCalendarEventsProvider.future).catchError((_) => <CalendarEvent>[]),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(todayEntriesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            tooltip: 'Search entries',
          ),
        ],
      ),
      body: Column(
        children: [
          // Agenda section at top — shows calendar events when connected
          AgendaSection(highlightEventId: highlightEventId),

          // Entries feed below with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _onRefresh(ref),
              child: entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Something went wrong',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: () => ref.invalidate(todayEntriesProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                data: (entries) {
                  if (entries.isEmpty) {
                    return _buildEmptyState(theme, colorScheme);
                  }
                  return _buildEntryList(context, entries);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state — motivating prompt when no entries exist for today.
  /// Wrapped in a scrollable so pull-to-refresh works.
  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_note,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withAlpha(102),
                ),
                const SizedBox(height: 16),
                Text(
                  'What did you work on today?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to capture your first reflection',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(153),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The entry feed — reverse chronological list of entry cards.
  Widget _buildEntryList(BuildContext context, List<Entry> entries) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EntryCard(
            entry: entry,
            onTap: () => _openEntryDetail(context, entry),
          ),
        );
      },
    );
  }
}
