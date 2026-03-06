import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/entry_repository.dart';
import '../domain/entry.dart';
import 'entry_providers.dart';

/// Full-view screen for a single Daily Canvas entry.
///
/// Supports toggling between read mode and edit mode. Provides delete
/// functionality with an undo snackbar that re-creates the entry on undo.
///
/// Receives an [Entry] via constructor. Edit saves via
/// [EntryRepository.updateEntry]; delete calls [EntryRepository.deleteEntry]
/// then pops back and shows a snackbar with undo.
class EntryDetailScreen extends ConsumerStatefulWidget {
  final Entry entry;

  const EntryDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  late TextEditingController _controller;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.entry.body);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Formats the entry's creation date/time for the detail header.
  String _formatDate(DateTime createdAt) {
    return DateFormat.yMMMd().add_jm().format(createdAt); // e.g., "Mar 3, 2026, 2:30 PM"
  }

  /// Saves the edited text via EntryRepository.updateEntry.
  Future<void> _saveEdit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry cannot be empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref.read(entryRepositoryProvider).updateEntry(
            entryId: widget.entry.id,
            body: text,
          );
      ref.invalidate(todayEntriesProvider);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[EntryDetailScreen] save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  /// Deletes the entry and shows an undo snackbar.
  ///
  /// The entry is deleted immediately. If the user taps "Undo" within
  /// 4 seconds, a new entry is created with the same body and inputMethod
  /// (it gets a new _id and _creationTime, which is acceptable for this
  /// short undo window).
  Future<void> _deleteEntry() async {
    final entry = widget.entry;
    final repo = ref.read(entryRepositoryProvider);

    // Capture messenger before popping
    final messenger = ScaffoldMessenger.of(context);

    try {
      // Delete immediately
      await repo.deleteEntry(entry.id);
      ref.invalidate(todayEntriesProvider);

      if (mounted) {
        // Pop back to the feed
        Navigator.pop(context);

        // Show undo snackbar on the parent screen
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Entry deleted'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // Re-create the entry with the same content
                await repo.createEntry(
                  userId: entry.userId,
                  body: entry.body,
                  inputMethod: entry.inputMethod,
                );
                ref.invalidate(todayEntriesProvider);
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[EntryDetailScreen] delete error: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Shows a confirmation dialog before deleting.
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This entry will be removed. You can undo this for a few seconds.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteEntry();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entry = widget.entry;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _formatDate(entry.createdAt),
          style: theme.textTheme.titleSmall,
        ),
        actions: [
          if (!_isEditing) ...[
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit entry',
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Delete entry',
            ),
          ] else ...[
            // Cancel edit
            TextButton(
              onPressed: () {
                _controller.text = entry.body;
                setState(() => _isEditing = false);
              },
              child: const Text('Cancel'),
            ),
            // Save edit
            TextButton(
              onPressed: _isSaving ? null : _saveEdit,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voice entry indicator
            if (entry.isVoice)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withAlpha(153),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Voice entry',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),

            // Entry body — read or edit mode
            if (_isEditing)
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write your reflection...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              )
            else
              SelectableText(
                entry.body,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurface,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
