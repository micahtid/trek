import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/entry_repository.dart';
import '../domain/entry.dart';
import 'entry_card.dart';
import 'entry_detail_screen.dart';
import 'entry_providers.dart';

/// Full-screen search experience for Daily Canvas entries.
///
/// Provides debounced full-text search across all entries (not just today),
/// optional date range filtering via [showDateRangePicker], and results
/// displayed as [EntryCard] widgets grouped by date. Launched from the
/// search icon in TodayScreen's app bar.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Entry>? _results;
  bool _isSearching = false;
  String? _errorMessage;

  // Date range filter state
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Debounces search input by 300ms to avoid excessive API calls.
  void _onQueryChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  /// Executes the search query against the Convex backend.
  ///
  /// Uses [EntryRepository.searchEntries] with the current query text
  /// and optional date range filter. Handles whitespace-only queries
  /// as empty (clears results).
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _results = null;
        _isSearching = false;
        _errorMessage = null;
      });
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      setState(() {
        _errorMessage = 'Not signed in';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      // Convert date range to Unix milliseconds if set
      int? startDate;
      int? endDate;
      if (_dateRange != null) {
        startDate = _dateRange!.start.millisecondsSinceEpoch;
        // End of the end day (23:59:59.999) to include the entire day
        endDate = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
          999,
        ).millisecondsSinceEpoch;
      }

      final results = await ref.read(entryRepositoryProvider).searchEntries(
            userId: userId,
            searchText: query,
            startDate: startDate,
            endDate: endDate,
          );

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('[SearchScreen] search error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Search failed. Tap to retry.';
          _isSearching = false;
        });
      }
    }
  }

  /// Opens the date range picker and triggers a new search if a range
  /// is selected.
  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: now,
      initialDateRange: _dateRange,
      builder: (context, child) {
        return child!;
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      // Re-run search with new date filter if there is a query
      if (_searchController.text.trim().isNotEmpty) {
        _performSearch();
      }
    }
  }

  /// Clears the active date range filter and re-runs the search.
  void _clearDateFilter() {
    setState(() {
      _dateRange = null;
    });
    if (_searchController.text.trim().isNotEmpty) {
      _performSearch();
    }
  }

  /// Groups a flat list of entries by their creation date (year-month-day).
  ///
  /// Returns a map ordered by date descending (newest first). Each key
  /// is the date portion of the entry's createdAt timestamp.
  Map<DateTime, List<Entry>> _groupByDate(List<Entry> entries) {
    final grouped = <DateTime, List<Entry>>{};
    for (final entry in entries) {
      final dt = entry.createdAt;
      final dateKey = DateTime(dt.year, dt.month, dt.day);
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }

    // Sort keys descending (newest date first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return {for (final key in sortedKeys) key: grouped[key]!};
  }

  /// Formats a date header for the grouped results.
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat.yMMMEd().format(date); // e.g., "Tue, Mar 3, 2026"
  }

  /// Formats the active date range for display as a chip label.
  String _formatDateRange(DateTimeRange range) {
    final startFmt = DateFormat.MMMd().format(range.start);
    final endFmt = DateFormat.MMMd().format(range.end);
    return '$startFmt - $endFmt';
  }

  void _openEntryDetail(Entry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntryDetailScreen(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final query = _searchController.text.trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search entries...',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            border: InputBorder.none,
          ),
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          // Filter icon button — opens date range picker
          IconButton(
            icon: Icon(
              _dateRange != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _dateRange != null
                  ? colorScheme.primary
                  : null,
            ),
            onPressed: _pickDateRange,
            tooltip: 'Filter by date range',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active date filter chip
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: InputChip(
                label: Text(_formatDateRange(_dateRange!)),
                onDeleted: _clearDateFilter,
                avatar: const Icon(Icons.date_range, size: 18),
              ),
            ),

          // Search body — different states
          Expanded(
            child: _buildBody(theme, colorScheme, query),
          ),
        ],
      ),
    );
  }

  /// Builds the appropriate body content based on current search state.
  Widget _buildBody(ThemeData theme, ColorScheme colorScheme, String query) {
    // Error state
    if (_errorMessage != null) {
      return Center(
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
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _performSearch,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty query — show helper
    if (query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: colorScheme.onSurfaceVariant.withAlpha(102),
              ),
              const SizedBox(height: 16),
              Text(
                'Search across all your entries',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Find past reflections by keyword',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(153),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // No results
    if (_results != null && _results!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: colorScheme.onSurfaceVariant.withAlpha(102),
              ),
              const SizedBox(height: 16),
              Text(
                'No entries found for "$query"',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_dateRange != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Try removing the date filter',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(153),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Results — grouped by date
    if (_results != null && _results!.isNotEmpty) {
      return _buildGroupedResults(theme, colorScheme);
    }

    // Default fallback (should not happen)
    return const SizedBox.shrink();
  }

  /// Builds the grouped results list with date headers and [EntryCard] items.
  Widget _buildGroupedResults(ThemeData theme, ColorScheme colorScheme) {
    final grouped = _groupByDate(_results!);
    final dateKeys = grouped.keys.toList();

    // Build a flat list of widgets: date headers + entry cards
    final items = <_SearchListItem>[];
    for (final dateKey in dateKeys) {
      items.add(_SearchListItem.header(_formatDateHeader(dateKey)));
      for (final entry in grouped[dateKey]!) {
        items.add(_SearchListItem.entry(entry));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isHeader) {
          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0 : 16,
              bottom: 8,
            ),
            child: Text(
              item.headerText!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EntryCard(
            entry: item.entry!,
            onTap: () => _openEntryDetail(item.entry!),
          ),
        );
      },
    );
  }
}

/// A tagged union for search result list items — either a date header or an entry.
class _SearchListItem {
  final String? headerText;
  final Entry? entry;

  const _SearchListItem._({this.headerText, this.entry});

  factory _SearchListItem.header(String text) =>
      _SearchListItem._(headerText: text);

  factory _SearchListItem.entry(Entry entry) =>
      _SearchListItem._(entry: entry);

  bool get isHeader => headerText != null;
}
