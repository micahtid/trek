# Phase 2: Daily Canvas - Research

**Researched:** 2026-03-03
**Domain:** Flutter CRUD + voice input + Convex real-time backend + full-text search
**Confidence:** HIGH

## Summary

Phase 2 transforms the placeholder `TodayScreen` into a frictionless daily workspace. The core technical domains are: (1) a Convex `entries` table with full-text search index, (2) CRUD operations via `convex_flutter` mutations/queries with real-time subscriptions, (3) voice-to-text transcription via `speech_to_text`, and (4) Flutter Material 3 UI patterns including FAB, modal bottom sheet for composing, and `SearchAnchor` for full-screen search.

The existing codebase provides solid foundations: `ConvexService` singleton with `mutation()` and `query()` wrappers, Riverpod state management with `AsyncNotifier` pattern, GoRouter shell navigation, and a Convex backend (v1.32+) already deployed at `grand-tortoise-682.convex.cloud`. The `convex_flutter` package (v3.0.1) also exposes a `subscribe()` method for real-time updates, which should power the live entry feed.

**Primary recommendation:** Build the entries table with a `searchIndex` on the `body` field and `userId` as a `filterField`, use `convex_flutter` subscriptions for the live feed, `speech_to_text` for voice input (it handles permissions internally), and standard Material 3 `showModalBottomSheet` for the compose surface.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Card stream layout -- each entry is a distinct card in a scrollable feed
- FAB (floating action button) opens a bottom sheet for composing new entries
- Bottom sheet is lightweight, slides up, and focuses on quick capture
- Canvas shows today's entries only -- past days accessible through search or history
- Mic button lives inside the compose bottom sheet, next to the text field
- Voice and text share the same compose surface -- unified input
- Transcription appears as editable text in the text field (draft-style, user can polish before saving)
- Voice entries display a subtle mic icon/badge on their card in the feed
- Cards show 2-3 line preview of entry text plus creation timestamp
- Tap a card to open full view with edit and delete actions inside
- Delete uses undo snackbar -- immediate deletion with a few-second undo window
- Empty state shows a motivating prompt (illustration/icon + "What did you work on today?")
- Search icon in the app bar opens a full-screen search experience
- Results displayed in same card format as the daily feed (preview + timestamp, grouped by date)
- Supports full-text search plus optional date range filtering
- Search covers all entries across all days

### Claude's Discretion
- Voice recording visual feedback (waveform, pulsing icon, etc.)
- Empty search results state design
- Exact card spacing, typography, and shadow styling
- Loading states and error handling
- How the bottom sheet expands for longer entries

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CANV-01 | User opens to a frictionless input surface for capturing daily reflections | TodayScreen becomes card-stream feed with FAB + bottom sheet compose; Convex subscription for real-time feed |
| CANV-02 | User can create, read, update, and delete text entries | Convex mutations (createEntry, updateEntry, deleteEntry) + queries (getEntriesToday, getEntry); convex_flutter v3.0.1 API |
| CANV-03 | User can input via voice, which is transcribed and converted to text | speech_to_text v7.3.0; mic button in compose bottom sheet; transcription into TextField as editable draft |
| CANV-05 | All input modes converge into clean, formatted text entries | Unified compose surface -- voice transcription and typed text both go into the same TextField before save |
| CANV-06 | User can search across all entries via full-text search | Convex searchIndex on entries.body with userId filterField; SearchAnchor full-screen search UI; date range via .filter() |
| CANV-07 | Each entry is auto-stamped with date and time metadata | Convex _creationTime system field (auto-set, millisecond Unix timestamp); no user input needed |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| convex_flutter | ^3.0.1 | Backend queries, mutations, subscriptions | Already in project; provides real-time WebSocket subscriptions, auth bridge |
| convex (backend) | ^1.32.0 | Schema, mutations, queries, search indexes | Already deployed; full-text search is built-in via searchIndex |
| speech_to_text | ^7.3.0 | On-device speech recognition | De facto Flutter STT package; 6000+ pub.dev likes; handles permissions internally |
| flutter_riverpod | ^3.2.1 | State management | Already in project; AsyncNotifier pattern established in Phase 1 |
| go_router | ^17.1.0 | Navigation | Already in project; shell route pattern established |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| intl | ^0.20.0 | Date/time formatting for entry timestamps | Format _creationTime for card display (e.g., "2:30 PM", "Mar 3") |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| speech_to_text | Deepgram / Google Cloud STT | Cloud APIs need API keys, network dependency, cost; on-device is free and offline-capable |
| Convex full-text search | Algolia / Typesense | External search service adds complexity; Convex search is built-in, transactional, reactive |
| SearchAnchor | Custom search UI | Material 3 SearchAnchor provides standard full-screen search with zero custom code |

**Installation:**
```bash
flutter pub add speech_to_text intl
```

No Convex changes needed -- `convex_flutter` and `convex` are already installed.

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── core/
│   └── convex/
│       └── convex_service.dart          # Existing -- add subscribe() wrapper
├── features/
│   └── today/
│       ├── data/
│       │   └── entry_repository.dart    # Convex CRUD + subscription bridge
│       ├── domain/
│       │   └── entry.dart               # Entry data model (fromJson)
│       ├── presentation/
│       │   ├── today_screen.dart         # Card feed + FAB + search icon
│       │   ├── entry_card.dart           # Reusable card widget
│       │   ├── compose_sheet.dart        # Bottom sheet with TextField + mic
│       │   ├── entry_detail_screen.dart  # Full view with edit/delete
│       │   ├── search_screen.dart        # Full-screen search experience
│       │   └── entry_providers.dart      # Riverpod providers for entries
│       └── (no separate domain layer needed yet -- keep flat)
convex/                                   # Backend (separate repo)
├── schema.ts                             # Add entries table + searchIndex
├── entries.ts                            # CRUD mutations + queries
└── users.ts                              # Existing
```

### Pattern 1: Convex Entries Schema with Search Index
**What:** Define the entries table with full-text search capability
**When to use:** Schema definition in the Convex backend
**Example:**
```typescript
// Source: https://docs.convex.dev/search/text-search
// File: convex/schema.ts
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    // ... existing fields
  })
    .index("by_googleId", ["googleId"])
    .index("by_email", ["email"]),

  entries: defineTable({
    userId: v.string(),        // Google ID of the owning user
    body: v.string(),          // Entry text content
    inputMethod: v.string(),   // "text" | "voice" -- for mic badge display
  })
    .index("by_user_creation", ["userId"])  // Filter today's entries by user, ordered by _creationTime
    .searchIndex("search_body", {
      searchField: "body",
      filterFields: ["userId"],             // Scope search to current user's entries
    }),
});
```

**Key decisions:**
- `userId` is `v.string()` (Google ID), not `v.id("users")` -- matches existing auth pattern where `AuthStateAuthenticated.userId` can be either a Convex doc ID or fallback Google ID
- `_creationTime` is auto-set by Convex (millisecond Unix timestamp) -- no explicit timestamp field needed (satisfies CANV-07)
- `inputMethod` tracks whether entry was typed or spoken (for the mic badge on voice entries)
- `_creationTime` is automatically appended as the last column of every index, so `by_user_creation` on `["userId"]` returns entries ordered by creation time

### Pattern 2: Convex CRUD Mutations and Queries
**What:** Backend functions for entry lifecycle
**When to use:** convex/entries.ts
**Example:**
```typescript
// Source: https://docs.convex.dev/database/schemas
// File: convex/entries.ts
import { mutation, query } from "./_generated/server";
import { v } from "convex/values";

export const createEntry = mutation({
  args: {
    userId: v.string(),
    body: v.string(),
    inputMethod: v.string(),
  },
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");
    return await ctx.db.insert("entries", {
      userId: args.userId,
      body: args.body,
      inputMethod: args.inputMethod,
    });
  },
});

export const getEntriesToday = query({
  args: { userId: v.string(), startOfDay: v.number() },
  handler: async (ctx, args) => {
    // Get entries for this user created after startOfDay
    const entries = await ctx.db
      .query("entries")
      .withIndex("by_user_creation", (q) => q.eq("userId", args.userId))
      .filter((q) => q.gte(q.field("_creationTime"), args.startOfDay))
      .order("desc")
      .collect();
    return entries;
  },
});

export const updateEntry = mutation({
  args: { entryId: v.id("entries"), body: v.string() },
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");
    await ctx.db.patch(args.entryId, { body: args.body });
  },
});

export const deleteEntry = mutation({
  args: { entryId: v.id("entries") },
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");
    await ctx.db.delete(args.entryId);
  },
});

export const searchEntries = query({
  args: { userId: v.string(), searchText: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("entries")
      .withSearchIndex("search_body", (q) =>
        q.search("body", args.searchText).eq("userId", args.userId)
      )
      .take(50);
  },
});
```

### Pattern 3: Riverpod + Convex Subscription for Live Feed
**What:** Bridge convex_flutter subscriptions into Riverpod state
**When to use:** Entry providers connecting backend to UI
**Example:**
```dart
// Source: https://pub.dev/packages/convex_flutter
// File: lib/features/today/presentation/entry_providers.dart
import 'dart:convert';
import 'package:convex_flutter/convex_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final todayEntriesProvider = StreamProvider.autoDispose<List<Entry>>((ref) {
  final controller = StreamController<List<Entry>>();

  // Calculate start of today in UTC milliseconds
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    controller.add([]);
    return controller.stream;
  }

  // Subscribe to real-time updates via convex_flutter
  late final ConvexSubscription sub;
  ConvexClient.instance.subscribe(
    name: 'entries:getEntriesToday',
    args: {'userId': userId, 'startOfDay': startOfDay.toString()},
    onUpdate: (value) {
      final List<dynamic> decoded = json.decode(value);
      final entries = decoded.map((e) => Entry.fromJson(e)).toList();
      controller.add(entries);
    },
    onError: (message, value) {
      controller.addError(Exception(message));
    },
  ).then((s) => sub = s);

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});
```

### Pattern 4: Bottom Sheet with Keyboard Handling
**What:** Compose bottom sheet that moves above keyboard
**When to use:** FAB tap opens compose surface
**Example:**
```dart
// Source: https://api.flutter.dev/flutter/material/showModalBottomSheet.html
void _openComposeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,  // CRITICAL: allows sheet to resize with keyboard
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,  // Push above keyboard
      ),
      child: const ComposeSheet(),
    ),
  );
}
```

### Pattern 5: speech_to_text Integration
**What:** Voice capture in compose bottom sheet
**When to use:** Mic button in compose surface
**Example:**
```dart
// Source: https://pub.dev/packages/speech_to_text
import 'package:speech_to_text/speech_to_text.dart' as stt;

class _ComposeSheetState extends State<ComposeSheet> {
  final _speech = stt.SpeechToText();
  final _controller = TextEditingController();
  bool _isListening = false;

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done') setState(() => _isListening = false);
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          // Insert transcription into TextField (draft-style, editable)
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        },
      );
    }
  }
}
```

### Anti-Patterns to Avoid
- **Polling for entries instead of subscribing:** convex_flutter has real-time subscriptions -- use them, don't poll with Timer
- **Storing timestamps manually:** Convex `_creationTime` is automatic and consistent -- don't add a custom `createdAt` field
- **Using `v.id("users")` for userId in entries:** The current auth pattern uses Google ID strings as fallback -- use `v.string()` to match
- **Creating separate voice and text compose flows:** User decision mandates unified compose surface
- **Using `showSearch()` (deprecated):** Use `SearchAnchor` instead -- it's the Material 3 replacement

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Full-text search | Custom substring matching or client-side filtering | Convex `searchIndex` | BM25 scoring, fuzzy matching, prefix matching, transactional consistency |
| Speech recognition | Raw microphone streams + cloud API calls | `speech_to_text` package | Handles platform permissions, on-device processing, result streaming |
| Bottom sheet | Custom overlay/positioned widget | `showModalBottomSheet` | Handles backdrop, drag-to-dismiss, keyboard avoidance, Material 3 theming |
| Date/time formatting | Manual string formatting | `intl` package `DateFormat` | Locale-aware, handles edge cases (midnight, timezone) |
| Search UI | Custom text field + overlay | `SearchAnchor` widget | Material 3 compliant, full-screen on mobile by default, animation built-in |
| Undo for delete | Custom timer + state management | `ScaffoldMessenger.showSnackBar` with `SnackBarAction` | Standard pattern, handles duration, auto-dismiss, action callback |

**Key insight:** Every major feature in this phase has a well-established Flutter or Convex pattern. The risk is in wiring them together, not in building any individual piece.

## Common Pitfalls

### Pitfall 1: Bottom Sheet Hidden Behind Keyboard
**What goes wrong:** TextField in bottom sheet is obscured when keyboard opens
**Why it happens:** `isScrollControlled` defaults to `false`, preventing resize
**How to avoid:** Always set `isScrollControlled: true` and add `padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)` to the bottom sheet content
**Warning signs:** Users can't see what they're typing in the compose sheet

### Pitfall 2: speech_to_text 60-Second iOS Limit
**What goes wrong:** Recording silently stops after 60 seconds on iOS
**Why it happens:** Apple enforces a maximum recognition session duration
**How to avoid:** Show a visual timer or countdown; auto-stop and save before the limit; design for short reflections (which aligns with the bottom sheet quick-capture UX)
**Warning signs:** Users report voice entries cutting off without warning

### Pitfall 3: speech_to_text Android Pause Timeout
**What goes wrong:** Recognition stops when user pauses briefly while speaking
**Why it happens:** Android's speech recognizer has a built-in silence detector
**How to avoid:** Document this behavior in UX; show clear listening status indicator; make it easy to tap mic again to continue
**Warning signs:** Partial transcriptions, missing end of sentences

### Pitfall 4: Convex Search Returns Max 1024 Results
**What goes wrong:** Power users with many entries may hit the scan limit
**Why it happens:** Convex full-text search scans at most 1024 documents per query
**How to avoid:** Use `userId` as a `filterField` (not a `.filter()`) so the index narrows before scanning; paginate results with `.take(n)`; show "top 50 results" rather than "all results"
**Warning signs:** Search results feel incomplete for users with hundreds of entries

### Pitfall 5: Timezone Mismatch for "Today's Entries"
**What goes wrong:** Entries from late evening or early morning show on wrong day
**Why it happens:** `_creationTime` is UTC milliseconds; "today" depends on user's local timezone
**How to avoid:** Calculate `startOfDay` in the client using `DateTime.now()` (local time), convert to milliseconds, pass to Convex query
**Warning signs:** Entries created near midnight appear on the wrong day's canvas

### Pitfall 6: Convex Subscription Leak in Riverpod
**What goes wrong:** Subscriptions accumulate, causing duplicate updates or memory leaks
**Why it happens:** Not canceling the subscription when the provider is disposed
**How to avoid:** Always call `sub.cancel()` in `ref.onDispose()`; use `StreamProvider.autoDispose` so disposal happens automatically when no widgets are listening
**Warning signs:** Multiple rapid updates for a single change, increasing memory usage

### Pitfall 7: Delete Without Undo Loses Data
**What goes wrong:** Accidental delete permanently removes an entry
**Why it happens:** Convex `db.delete()` is permanent
**How to avoid:** Show SnackBar with undo action; delay the actual Convex mutation by the snackbar duration; if user taps undo, cancel the pending mutation
**Warning signs:** Users accidentally delete entries with no recovery option

## Code Examples

Verified patterns from official sources:

### Convex Search with Date Filtering
```typescript
// Source: https://docs.convex.dev/search/text-search
// Search entries by text, scoped to user, with date range
export const searchEntriesWithDateRange = query({
  args: {
    userId: v.string(),
    searchText: v.string(),
    startDate: v.optional(v.number()),  // Unix ms
    endDate: v.optional(v.number()),    // Unix ms
  },
  handler: async (ctx, args) => {
    let q = ctx.db
      .query("entries")
      .withSearchIndex("search_body", (q) =>
        q.search("body", args.searchText).eq("userId", args.userId)
      );

    if (args.startDate !== undefined) {
      q = q.filter((q) => q.gte(q.field("_creationTime"), args.startDate!));
    }
    if (args.endDate !== undefined) {
      q = q.filter((q) => q.lte(q.field("_creationTime"), args.endDate!));
    }

    return await q.take(50);
  },
});
```

### Entry Data Model (Dart)
```dart
// Entry model matching Convex document shape
class Entry {
  final String id;           // Convex _id
  final String userId;
  final String body;
  final String inputMethod;  // "text" | "voice"
  final int creationTime;    // Convex _creationTime (Unix ms)

  const Entry({
    required this.id,
    required this.userId,
    required this.body,
    required this.inputMethod,
    required this.creationTime,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      body: json['body'] as String,
      inputMethod: json['inputMethod'] as String,
      creationTime: (json['_creationTime'] as num).toInt(),
    );
  }

  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(creationTime);

  bool get isVoice => inputMethod == 'voice';
}
```

### Undo Delete Pattern
```dart
// Source: Flutter Material Design guidelines
void _deleteEntry(BuildContext context, WidgetRef ref, Entry entry) {
  // Optimistically remove from UI immediately
  // (Riverpod state update or let subscription handle it)

  // Show undo snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Entry deleted'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // Re-create the entry (or cancel pending delete)
          ref.read(entryRepositoryProvider).createEntry(
            userId: entry.userId,
            body: entry.body,
            inputMethod: entry.inputMethod,
          );
        },
      ),
    ),
  );

  // Execute delete immediately (undo re-creates)
  ref.read(entryRepositoryProvider).deleteEntry(entry.id);
}
```

### SearchAnchor Full-Screen Search
```dart
// Source: https://api.flutter.dev/flutter/material/SearchAnchor-class.html
SearchAnchor(
  isFullScreen: true,
  builder: (context, controller) {
    return IconButton(
      icon: const Icon(Icons.search),
      onPressed: () => controller.openView(),
    );
  },
  suggestionsBuilder: (context, controller) async {
    if (controller.text.isEmpty) return [];
    final results = await ref.read(entryRepositoryProvider)
        .searchEntries(userId: userId, searchText: controller.text);
    return results.map((entry) => EntryCard(entry: entry)).toList();
  },
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `showSearch()` delegate | `SearchAnchor` widget | Flutter 3.7+ (2023) | Material 3 compliant, simpler API, full-screen default on mobile |
| Manual Convex polling | `convex_flutter` subscriptions | convex_flutter 3.0 (2025) | Real-time updates via WebSocket, no polling needed |
| `speech_to_text` v6 | `speech_to_text` v7.3.0 | 2025 | Windows beta support, improved Android stability |
| `convex_flutter` v1 | `convex_flutter` v3.0.1 | 2025 | Rust core, connection state monitoring, lifecycle events |

**Deprecated/outdated:**
- `showSearch()`: Replaced by `SearchAnchor` in Material 3; still works but not recommended for new projects
- `speech_recognition` package: Abandoned; `speech_to_text` is the maintained successor

## Open Questions

1. **convex_flutter subscribe() argument serialization**
   - What we know: `query()` and `mutation()` accept `Map<String, dynamic>` args, subscribe likely does too
   - What's unclear: Whether numeric args (like `startOfDay`) need to be passed as strings or can be native numbers; convex_flutter API docs are sparse on this
   - Recommendation: Test during implementation; if numbers fail, stringify them

2. **convex_flutter subscribe() return type**
   - What we know: Subscribe returns a subscription handle that can be canceled
   - What's unclear: Exact return type name and whether it's a Future or synchronous
   - Recommendation: The pattern `ConvexClient.instance.subscribe(...).then((s) => sub = s)` from official docs suggests it returns `Future<ConvexSubscription>` -- verify at implementation time

3. **Undo delete: re-create vs. soft-delete**
   - What we know: Convex `db.delete()` is permanent; the user decision says "undo snackbar"
   - What's unclear: Whether to implement as immediate-delete + re-create-on-undo, or delayed-delete (timer-based)
   - Recommendation: Immediate delete + re-create on undo is simpler and matches Convex's model; the re-created entry gets a new `_id` and `_creationTime` but this is acceptable for the undo UX since the snackbar window is only a few seconds

## Sources

### Primary (HIGH confidence)
- [Convex Full-Text Search](https://docs.convex.dev/search/text-search) - Search index definition, query syntax, limitations (1024 doc scan limit, 16 filter fields)
- [Convex Schemas](https://docs.convex.dev/database/schemas) - System fields (_id, _creationTime), index definition, userId association pattern
- [convex_flutter pub.dev](https://pub.dev/packages/convex_flutter) - v3.0.1 API: query, mutation, subscribe, auth, connection state
- [speech_to_text pub.dev](https://pub.dev/packages/speech_to_text) - v7.3.0 API: initialize, listen, stop, platform permissions
- [showModalBottomSheet API](https://api.flutter.dev/flutter/material/showModalBottomSheet.html) - isScrollControlled, keyboard handling
- [SearchAnchor API](https://api.flutter.dev/flutter/material/SearchAnchor-class.html) - Full-screen search, suggestionsBuilder

### Secondary (MEDIUM confidence)
- [Flutter keyboard + bottom sheet fix](https://apparencekit.dev/blog/bottom-sheet-flutter-keyboard-fix/) - MediaQuery.viewInsets.bottom pattern verified against multiple sources
- [Convex full-text search overview](https://www.convex.dev/can-do/search) - BM25 scoring, fuzzy matching, prefix matching capabilities

### Tertiary (LOW confidence)
- convex_flutter subscribe() exact argument serialization - only pub.dev readme examples available; needs implementation-time verification

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries verified on pub.dev and official docs; versions confirmed
- Architecture: HIGH - Convex CRUD + search patterns well-documented; Flutter bottom sheet / SearchAnchor are standard Material 3
- Pitfalls: HIGH - Keyboard/bottom sheet issues, speech_to_text limits, and Convex search limits all documented in official sources
- Convex-Flutter subscription wiring: MEDIUM - subscribe() API confirmed but Riverpod integration pattern is inferred, not from official examples

**Research date:** 2026-03-03
**Valid until:** 2026-04-03 (30 days -- all libraries are stable releases)
