import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

// ─── Model ────────────────────────────────────────────────────────────────────

class Note {
  final String id;
  String title;
  String content;
  DateTime modifiedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.modifiedAt,
  });
}

// ─── App ──────────────────────────────────────────────────────────────────────

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        fontFamily: '.SF Pro Text',
      ),
      home: const NotesListPage(),
    );
  }
}

// ─── Notes List ───────────────────────────────────────────────────────────────

class NotesListPage extends StatefulWidget {
  const NotesListPage({super.key});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  final List<Note> _notes = [
    Note(
      id: '1',
      title: 'Grocery List',
      content: 'Milk\nEggs\nBread\nButter\nApples',
      modifiedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Note(
      id: '2',
      title: 'Project Ideas',
      content: '• Build a notes app\n• Learn Flutter\n• Create a portfolio website',
      modifiedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Note(
      id: '3',
      title: 'Meeting Notes',
      content: 'Date: Monday\nAttendees: Team\nTopics: Q1 goals, Budget review',
      modifiedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Note(
      id: '4',
      title: 'Book Recommendations',
      content: '1. Atomic Habits\n2. Deep Work\n3. The Lean Startup',
      modifiedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  Future<void> _openNote(Note note) async {
    bool deleted = false;

    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => NoteEditorPage(
          note: note,
          onDelete: () {
            deleted = true;
            Navigator.of(context).pop();
          },
        ),
      ),
    );

    setState(() {
      if (deleted || (note.title.isEmpty && note.content.isEmpty)) {
        _notes.remove(note);
      }
      _notes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    });
  }

  void _addNewNote() {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      content: '',
      modifiedAt: DateTime.now(),
    );
    setState(() => _notes.insert(0, note));
    _openNote(note);
  }

  // Format date like iOS Notes: time today, weekday this week, date otherwise
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(noteDay).inDays;

    if (diff == 0) {
      final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final m = date.minute.toString().padLeft(2, '0');
      final p = date.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $p';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  BorderRadius _getBorderRadius(int index) {
    if (_notes.length == 1) return BorderRadius.circular(12);
    if (index == 0) return const BorderRadius.vertical(top: Radius.circular(12));
    if (index == _notes.length - 1) return const BorderRadius.vertical(bottom: Radius.circular(12));
    return BorderRadius.zero;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // ── Scrollable content ──
          Expanded(
            child: CustomScrollView(
              slivers: [
                // iOS large-title app bar
                const SliverAppBar.large(
                  backgroundColor: Color(0xFFF2F2F7),
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    'Notes',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),

                // Empty state
                if (_notes.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.doc_text, size: 64, color: Color(0xFFBCBCC0)),
                          SizedBox(height: 12),
                          Text(
                            'No Notes',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFBCBCC0),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap the compose button to get started.',
                            style: TextStyle(fontSize: 14, color: Color(0xFFBCBCC0)),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Notes list
                if (_notes.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final note = _notes[index];
                          final preview = note.content
                              .split('\n')
                              .map((l) => l.trim())
                              .firstWhere((l) => l.isNotEmpty, orElse: () => '');

                          return GestureDetector(
                            onTap: () => _openNote(note),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: _getBorderRadius(index),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Title
                                              Text(
                                                note.title.isEmpty ? 'New Note' : note.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 17,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              // Date + preview
                                              Row(
                                                children: [
                                                  Text(
                                                    _formatDate(note.modifiedAt),
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF8E8E93),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      preview.isEmpty ? 'No additional text' : preview,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(0xFF8E8E93),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          CupertinoIcons.chevron_right,
                                          color: Color(0xFFC7C7CC),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Separator (skip after last item)
                                  if (index != _notes.length - 1)
                                    const Divider(
                                      height: 1,
                                      indent: 16,
                                      color: Color(0xFFE5E5EA),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _notes.length,
                      ),
                    ),
                  ),

                // Note count below the list
                if (_notes.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 8),
                      child: Center(
                        child: Text(
                          '${_notes.length} ${_notes.length == 1 ? 'Note' : 'Notes'}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom toolbar (iOS Notes style) ──
          Container(
            padding: EdgeInsets.only(
              top: 8,
              bottom: bottomPad > 0 ? bottomPad : 16,
              left: 16,
              right: 8,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              border: Border(top: BorderSide(color: Color(0xFFD1D1D6), width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Spacer to balance the compose button
                const SizedBox(width: 48),
                Text(
                  '${_notes.length} ${_notes.length == 1 ? 'Note' : 'Notes'}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                // Compose button
                CupertinoButton(
                  padding: const EdgeInsets.all(8),
                  onPressed: _addNewNote,
                  child: const Icon(
                    CupertinoIcons.square_pencil,
                    color: Color(0xFFFFCC00),
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Note Editor ──────────────────────────────────────────────────────────────

class NoteEditorPage extends StatefulWidget {
  final Note note;
  final VoidCallback onDelete;

  const NoteEditorPage({
    super.key,
    required this.note,
    required this.onDelete,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _titleFocus;
  late final FocusNode _contentFocus;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _titleFocus = FocusNode();
    _contentFocus = FocusNode();

    // Auto-focus title field for new notes
    if (widget.note.title.isEmpty && widget.note.content.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _titleFocus.requestFocus());
    }
  }

  @override
  void dispose() {
    _persist();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  // Write edits back to the note object
  void _persist() {
    widget.note.title = _titleController.text.trim();
    widget.note.content = _contentController.text;
    if (widget.note.title.isNotEmpty || widget.note.content.isNotEmpty) {
      widget.note.modifiedAt = DateTime.now();
    }
  }

  void _confirmDelete() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Note'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop(); // dismiss dialog
              widget.onDelete();           // pop editor + signal delete
            },
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _headerDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day}, ${d.year} at $h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // Back button — "< Notes"
        leading: CupertinoButton(
          padding: const EdgeInsets.only(left: 4),
          onPressed: () => Navigator.of(context).pop(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.chevron_left, color: Color(0xFFFFCC00), size: 20),
              SizedBox(width: 2),
              Text(
                'Notes',
                style: TextStyle(
                  color: Color(0xFFFFCC00),
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        leadingWidth: 100,
        // Done button
        actions: [
          CupertinoButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Color(0xFFFFCC00),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E5EA)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Center(
                      child: Text(
                        _headerDate(widget.note.modifiedAt),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ),

                  // Title field
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocus,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBCBCC0),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _contentFocus.requestFocus(),
                    onChanged: (_) => _persist(),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: Color(0xFFE5E5EA)),
                  const SizedBox(height: 12),

                  // Body field — expands to fill available space
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.55,
                    ),
                    child: TextField(
                      controller: _contentController,
                      focusNode: _contentFocus,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                        height: 1.6,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Start typing…',
                        hintStyle: TextStyle(
                          fontSize: 17,
                          color: Color(0xFFBCBCC0),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (_) => _persist(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom toolbar ──
          Container(
            padding: EdgeInsets.only(
              top: 8,
              bottom: bottomPad > 0 ? bottomPad : 16,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _confirmDelete,
                  child: const Icon(CupertinoIcons.trash, color: Color(0xFFFFCC00), size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
