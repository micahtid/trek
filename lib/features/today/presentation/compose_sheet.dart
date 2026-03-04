import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../data/entry_repository.dart';
import 'entry_providers.dart';

/// Bottom sheet for composing a new Daily Canvas entry.
///
/// Provides a multiline text field with a mic button for voice dictation
/// (via speech_to_text) and a send button that creates the entry via
/// [EntryRepository.createEntry]. Tracks whether the input originated
/// from voice so the entry can be tagged with the correct inputMethod.
class ComposeSheet extends ConsumerStatefulWidget {
  const ComposeSheet({super.key});

  @override
  ConsumerState<ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<ComposeSheet> {
  final _controller = TextEditingController();
  final _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _speechAvailable = false;
  String _inputMethod = 'text';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  void _onTextChanged() {
    // Trigger rebuild so the send button enables/disables
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    // Initialize speech recognition if not already done
    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('[ComposeSheet] speech error: ${error.errorMsg}');
          setState(() => _isListening = false);
        },
        onStatus: (status) {
          // When speech recognition stops on its own (e.g., silence timeout)
          if (status == 'notListening' || status == 'done') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
      );

      if (!_speechAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone not available. Check app permissions.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    // Start listening
    setState(() {
      _isListening = true;
      _inputMethod = 'voice';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          // Move cursor to end of text
          _controller.selection = TextSelection.collapsed(
            offset: _controller.text.length,
          );
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _saveEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(entryRepositoryProvider).createEntry(
            userId: userId,
            body: text,
            inputMethod: _inputMethod,
          );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[ComposeSheet] save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save entry: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasText = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Text field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'What did you work on?',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                  border: InputBorder.none,
                ),
                style: theme.textTheme.bodyLarge,
              ),
            ),

            const SizedBox(height: 8),

            // Action row: mic + save
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  // Mic button with visual feedback when listening
                  IconButton(
                    onPressed: _isSaving ? null : _toggleListening,
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                    tooltip: _isListening ? 'Stop listening' : 'Voice input',
                  ),
                  // Listening indicator text
                  if (_isListening)
                    Text(
                      'Listening...',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  const Spacer(),
                  // Send button — enabled only when text is non-empty
                  FilledButton.icon(
                    onPressed: (hasText && !_isSaving) ? _saveEntry : null,
                    icon: _isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send, size: 18),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
