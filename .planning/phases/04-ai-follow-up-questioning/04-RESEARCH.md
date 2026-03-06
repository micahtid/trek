# Phase 4: AI Follow-Up Questioning - Research

**Researched:** 2026-03-04
**Domain:** Gemini AI integration (client-side via firebase_ai), chat UI, structured JSON output, entry enrichment
**Confidence:** MEDIUM-HIGH

## Summary

Phase 4 introduces the core AI differentiator: after creating an entry, the user enters a mini chat conversation where Gemini drills for specificity (percentages, counts, concrete outcomes). The enriched entry is then tagged with skills and impact level, and nudged toward one of five professional reflection categories. The conversation thread is ephemeral -- answers merge into the entry body as a polished paragraph.

The project currently has **no Firebase dependency** (no `firebase_core`, no `firebase_ai`, no `google-services.json`, no `firebase_options.dart`). This is the single largest prerequisite: Firebase must be bootstrapped before any Gemini API calls can happen. The recommended approach is client-side AI via `firebase_ai` (v3.9.0), which handles API key security via Firebase App Check and avoids embedding raw API keys in client code. The alternative -- server-side Convex actions calling `@google/genai` -- is viable but adds cold-start latency, requires managing API keys as Convex environment variables, and adds complexity without clear benefit for a chat-style interaction where streaming matters most.

**Primary recommendation:** Use client-side `firebase_ai` for the chat drill-down (streaming responses, multi-turn context management), and a separate `generateContent` call with structured JSON output (via `responseSchema`) for skill tagging and categorization after the drill-down completes.

<user_constraints>

## User Constraints (from CONTEXT.md)

### Locked Decisions
- Chat thread in entry detail view -- after saving an entry, user is auto-navigated to entry detail where AI questions appear as a mini conversation below the entry text
- AI asks up to 3-4 follow-up questions max, but user can dismiss early at any point via explicit "I'm done" button or back navigation
- Follow-up answers are merged into the original entry body -- AI consolidates the original text + answers into one clean, enriched reflection. The chat thread is ephemeral; the final entry reads as a polished paragraph
- Every new entry (text, voice, calendar reflection) triggers AI follow-up -- consistent experience across all entry types
- If user skips or navigates away mid-drill, they can resume the AI conversation later from entry detail ("Continue AI drill-down" option)
- Skill tags (#SQL, #PublicSpeaking, etc.) shown as colored chips below the entry text on feed cards -- visible at a glance
- Tags generated after the AI drill-down completes (not during) -- enriched entry body gives better tagging accuracy
- Users can accept or reject individual tags but cannot create new ones or rename -- AI controls the vocabulary
- AI's follow-up questions are crafted to naturally draw out category-relevant details -- subtle prompting, not rigid forms
- Category assigned after drill-down based on enriched content -- primary category displayed prominently, optional secondary categories shown smaller
- Users can fully override AI-assigned categories -- change primary, add/remove secondaries
- AI follow-up fires on every new entry -- text, voice, and calendar reflections all get drilled
- Skip/exit: explicit "I'm done" button always visible in the chat thread, plus back navigation also ends the session gracefully
- Interrupted conversations are resumable -- entry detail shows "Continue" option if drill-down was not completed

### Claude's Discretion
- Impact level visual design (dot, badge, stars, etc.)
- Category chip placement on entry cards
- Client-side vs. Convex server-side Gemini API calls
- Chat thread visual design (bubble style, spacing, animations)
- Loading states while waiting for Gemini responses
- Exact follow-up question phrasing and conversation flow
- How the entry body merge/consolidation works visually
- Error handling for Gemini API failures or rate limits

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope

</user_constraints>

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AI-01 | AI provides inline follow-up suggestions for specificity drilling | firebase_ai multi-turn chat with `startChat()` + `sendMessageStream()`, system instructions for coaching tone, structured prompts that demand percentages/counts/outcomes |
| AI-02 | AI automatically tags entries with skills and impact level | firebase_ai structured JSON output via `responseSchema` + `responseMimeType: 'application/json'`, post-drilldown tagging call with Schema.object |
| AI-03 | AI nudges entries toward professional reflection categories without forcing rigid structure | System instruction prompt engineering with the 5 categories as context; category assignment via structured output after drilldown |

</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase_core | latest | Firebase initialization, required by firebase_ai | Mandatory prerequisite for any Firebase service |
| firebase_ai | ^3.9.0 | Gemini API access (generateContent, startChat, streaming, structured output) | Official Google SDK for Gemini in Flutter; handles API key security via Firebase App Check |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_riverpod | ^3.2.1 | Already installed; state management for drilldown state, chat messages | All new providers for AI state |
| http | ^1.6.0 | Already installed; extended ConvexHttpService for action calls if needed | Convex backend mutations for saving AI metadata |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| firebase_ai (client-side) | Convex action + @google/genai (server-side) | Server-side hides API key fully but adds cold-start latency (1-3s), no streaming to client, more complex error handling. firebase_ai handles key security via Firebase App Check. |
| flutter_ai_toolkit (LlmChatView) | Custom chat UI widgets | LlmChatView is opinionated with limited customization for the ephemeral drill-down UX needed here (merge-to-body, "I'm done" button, resume). Custom UI is better. |
| chat_bubbles package | Custom DecoratedBox widgets | The drill-down is a 3-4 message mini-chat, not a full chat app. Minimal custom widgets are simpler than pulling in a chat package. |

### Discretion Decision: Client-Side AI (firebase_ai)

**Recommendation: Client-side via firebase_ai.** Rationale:
1. **Streaming** -- `sendMessageStream()` yields chunks as they arrive, enabling real-time typewriter effect in the chat thread. Server-side Convex actions cannot stream to the Flutter client.
2. **Multi-turn context** -- `startChat()` manages conversation history automatically. Server-side would require manually passing full history in each request.
3. **Latency** -- Direct client-to-Gemini is faster than client-to-Convex-action-to-Gemini-back-to-client roundtrip. Convex actions in the default runtime have cold starts; Node.js runtime actions are even slower.
4. **Security** -- firebase_ai uses Firebase App Check to protect the API key. The key never appears in client code; it stays in the Firebase project config.
5. **Simplicity** -- One SDK, one initialization. No need for Convex environment variables, action definitions, or bridge code.

**Installation:**
```bash
flutter pub add firebase_core firebase_ai
# Then: dart pub global activate flutterfire_cli
# Then: flutterfire configure (creates firebase_options.dart + google-services.json)
```

## Architecture Patterns

### Recommended Project Structure
```
lib/
  features/
    ai/                          # NEW — AI feature module
      data/
        ai_service.dart          # Wraps firebase_ai GenerativeModel + ChatSession
      domain/
        drilldown_state.dart     # State model: messages, status, round count
        ai_metadata.dart         # SkillTag, ImpactLevel, ReflectionCategory enums/models
      presentation/
        ai_providers.dart        # Riverpod providers for drilldown state
        drilldown_chat.dart      # Chat thread widget (bubbles, input, "I'm done")
        skill_chips.dart         # Colored skill tag chips widget
        category_badge.dart      # Category display widget
        impact_indicator.dart    # Impact level visual indicator
    today/
      domain/
        entry.dart               # EXTENDED — add skillTags, impactLevel, primaryCategory, etc.
      data/
        entry_repository.dart    # EXTENDED — add updateAiMetadata method
      presentation/
        entry_detail_screen.dart # EXTENDED — embed DrilldownChat below entry text
        entry_card.dart          # EXTENDED — show skill chips + category label
        compose_sheet.dart       # MODIFIED — after save, navigate to detail with drilldown active
```

### Pattern 1: AI Service Singleton
**What:** A wrapper class around `firebase_ai` that creates the GenerativeModel once with system instructions and exposes `startDrilldown()` and `analyzeEntry()` methods.
**When to use:** Every AI interaction in the app.
**Example:**
```dart
// Source: firebase.google.com/docs/ai-logic/chat + system-instructions
import 'package:firebase_ai/firebase_ai.dart';

class AiService {
  static final AiService instance = AiService._();
  AiService._();

  late final GenerativeModel _chatModel;
  late final GenerativeModel _analysisModel;

  void initialize() {
    _chatModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(_drilldownSystemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 300,
      ),
    );

    _analysisModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(_analysisSystemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _entryAnalysisSchema,
        temperature: 0.3,
      ),
    );
  }

  /// Starts a new drilldown chat session for an entry.
  ChatSession startDrilldown(String entryBody) {
    return _chatModel.startChat(history: [
      Content.text(entryBody), // Seed with the original entry
    ]);
  }

  /// Analyzes enriched entry for skills, impact, and category.
  Future<AiAnalysisResult> analyzeEntry(String enrichedBody) async {
    final response = await _analysisModel.generateContent([
      Content.text(enrichedBody),
    ]);
    return AiAnalysisResult.fromJson(jsonDecode(response.text!));
  }
}
```

### Pattern 2: Drilldown State Machine (Riverpod StateNotifier)
**What:** A `StateNotifier<DrilldownState>` that manages the chat lifecycle: idle -> questioning -> waiting -> answered -> complete.
**When to use:** Each entry detail screen with active drilldown.
**Example:**
```dart
enum DrilldownStatus { idle, active, waitingForAi, complete, error }

class DrilldownState {
  final DrilldownStatus status;
  final List<ChatMessage> messages; // user + AI messages
  final int roundCount;            // tracks how many Q&A rounds
  final String? enrichedBody;      // merged entry body after completion
  final String? errorMessage;

  const DrilldownState({
    this.status = DrilldownStatus.idle,
    this.messages = const [],
    this.roundCount = 0,
    this.enrichedBody,
    this.errorMessage,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  const ChatMessage({required this.text, required this.isUser, required this.timestamp});
}
```

### Pattern 3: Post-Drilldown Analysis Pipeline
**What:** After drilldown completes (user says "I'm done" or 3-4 rounds reached), a pipeline runs: (1) merge answers into entry body, (2) analyze enriched body for skills/impact/category, (3) update entry in Convex.
**When to use:** Every completed drilldown.
**Example:**
```dart
// After drilldown completes:
// 1. Ask Gemini to merge original + answers into polished paragraph
final mergePrompt = '''
Merge this original entry and the follow-up answers into a single polished
paragraph that reads like the user wrote it themselves. Do NOT include Q&A
format. Keep their voice and tone.

Original: $originalBody
Follow-up answers: ${answers.join('\n')}
''';
final merged = await chatModel.generateContent([Content.text(mergePrompt)]);

// 2. Analyze the merged text for skills, impact, category
final analysis = await aiService.analyzeEntry(merged.text!);

// 3. Update entry in Convex
await entryRepo.updateEntry(entryId: entryId, body: merged.text!);
await entryRepo.updateAiMetadata(
  entryId: entryId,
  skillTags: analysis.skillTags,
  impactLevel: analysis.impactLevel,
  primaryCategory: analysis.primaryCategory,
  secondaryCategories: analysis.secondaryCategories,
);
```

### Pattern 4: Structured JSON Output for Analysis
**What:** Use `responseSchema` with `responseMimeType: 'application/json'` to get guaranteed-structure JSON from Gemini for skill tagging and categorization.
**When to use:** The analysis step after drilldown completes.
**Example:**
```dart
// Source: firebase.google.com/docs/ai-logic/generate-structured-output
final analysisSchema = Schema.object(
  properties: {
    'skillTags': Schema.array(items: Schema.string()),
    'impactLevel': Schema.enumString(
      enumValues: ['low', 'medium', 'high', 'critical'],
    ),
    'primaryCategory': Schema.enumString(
      enumValues: [
        'key_learnings',
        'mistakes_and_lessons',
        'next_steps',
        'questions',
        'what_i_built',
      ],
    ),
    'secondaryCategories': Schema.array(
      items: Schema.enumString(
        enumValues: [
          'key_learnings',
          'mistakes_and_lessons',
          'next_steps',
          'questions',
          'what_i_built',
        ],
      ),
    ),
  },
);
```

### Anti-Patterns to Avoid
- **Calling Gemini on every keystroke:** Only trigger the drilldown AFTER the entry is saved, not during typing. The drill-down is a post-creation conversation.
- **Storing chat history permanently:** The chat thread is ephemeral. Only the merged body and analysis metadata persist. Storing full chat wastes Convex storage.
- **Blocking the save flow on AI:** Entry creation must succeed even if AI is unavailable. The drilldown is an enhancement, not a gate.
- **Using generateContent for chat:** Use `startChat()` + `sendMessage()`/`sendMessageStream()` for multi-turn. Raw `generateContent` loses conversation context.
- **Creating a separate GenerativeModel per request:** Create the model once in `AiService.initialize()` and reuse it. The `ChatSession` from `startChat()` is the per-conversation object.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-turn conversation state | Manual message history array passed to each API call | `model.startChat()` + `ChatSession` | firebase_ai manages history automatically; you just call `sendMessage()` |
| API key security | Hardcoded Gemini API key in app or env vars | Firebase App Check via firebase_ai | Keys in client code can be extracted; Firebase proxies securely |
| JSON parsing from AI output | String parsing, regex on Gemini text output | `responseSchema` + `responseMimeType: 'application/json'` | Gemini guarantees schema-conformant JSON; no parsing errors |
| Streaming text display | Polling or manual chunk assembly | `sendMessageStream()` + `await for (final chunk in stream)` | Built-in streaming yields chunks; just append to display |
| Chat message alignment | Custom alignment logic | Simple `isUser` bool + CrossAxisAlignment | Only 2 participants (user + AI); trivial alignment |

**Key insight:** The firebase_ai SDK handles the three hardest parts -- API key security, conversation state management, and structured output enforcement. Everything else is straightforward Flutter UI.

## Common Pitfalls

### Pitfall 1: Firebase Not Initialized Before AI Calls
**What goes wrong:** `FirebaseAI.googleAI()` throws if `Firebase.initializeApp()` hasn't been called.
**Why it happens:** The project currently has zero Firebase dependencies. Adding firebase_ai requires the full Firebase bootstrap.
**How to avoid:** Initialize Firebase in `main.dart` BEFORE anything else. The `firebase_options.dart` file from `flutterfire configure` provides platform configs.
**Warning signs:** `No Firebase App '[DEFAULT]' has been created` exception.

### Pitfall 2: google-services.json Missing for Android
**What goes wrong:** Android build fails with `File google-services.json is missing from module root`.
**Why it happens:** `flutterfire configure` must be run AND its output committed. The file goes in `android/app/google-services.json`.
**How to avoid:** Run `flutterfire configure` as a dedicated setup step. Verify the file exists before proceeding.
**Warning signs:** Gradle build errors mentioning google-services.

### Pitfall 3: System Instruction Too Vague
**What goes wrong:** Gemini asks generic questions ("Tell me more") instead of drilling for specifics.
**Why it happens:** System instruction doesn't establish the "casual coach demanding specificity" persona clearly enough.
**How to avoid:** System instruction must explicitly name the behaviors: ask for percentages, counts, named technologies, concrete outcomes. Include few-shot examples.
**Warning signs:** AI questions feel like a generic chatbot, not an intern coach.

### Pitfall 4: Drilldown Not Resumable After Navigation
**What goes wrong:** User navigates away mid-drilldown, returns to entry detail, and the drilldown state is gone.
**Why it happens:** Riverpod `autoDispose` providers lose state when the widget tree unmounts. ChatSession is in-memory only.
**How to avoid:** Persist drilldown state (messages + round count + status) to Convex. On re-entry, reconstruct the ChatSession with history from the saved messages. Store an `aiDrilldownStatus` field on the entry: 'pending' | 'in_progress' | 'complete' | 'skipped'.
**Warning signs:** "Continue" button appears but chat starts over from scratch.

### Pitfall 5: Entry Body Merge Produces Q&A Format
**What goes wrong:** The merged entry reads like "Q: What percentage? A: About 30%" instead of a natural paragraph.
**Why it happens:** The merge prompt doesn't emphasize enough that the output should read as if the user wrote it.
**How to avoid:** Explicit merge prompt: "Write in first person. Do NOT include questions or Q&A format. Keep the user's voice. The result should read like a journal entry the user typed themselves."
**Warning signs:** Merged entries contain "Q:" or "A:" or bullet-point Q&A structure.

### Pitfall 6: Structured Output Schema Mismatch
**What goes wrong:** Gemini returns JSON that doesn't match expected Dart model fields.
**Why it happens:** `responseSchema` was slightly different from the Dart parsing code.
**How to avoid:** Define the schema in one place and derive both the `Schema` object and the Dart model from it. Test with real entries before deploying.
**Warning signs:** `FormatException` or null fields when parsing AI analysis response.

### Pitfall 7: Rate Limiting or Quota Exhaustion
**What goes wrong:** Gemini API returns 429 or quota errors after many drilldowns.
**Why it happens:** Free tier has per-minute and per-day limits. Each drilldown makes 3-6 API calls (questions + merge + analysis).
**How to avoid:** Implement exponential backoff retry for transient errors. Show graceful error state ("AI is busy, try again in a moment"). Consider caching analysis results.
**Warning signs:** Errors appear during high-usage testing.

## Code Examples

### Firebase Initialization (main.dart update)
```dart
// Source: firebase.google.com/docs/flutter/setup
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize AI service after Firebase
  AiService.instance.initialize();

  // ... rest of existing main.dart
}
```

### System Instruction for Drilldown
```dart
const _drilldownSystemPrompt = '''
You are a casual, encouraging intern career coach. Your job is to help interns
write specific, quantified reflections about their work.

RULES:
- Ask ONE follow-up question at a time
- Your questions should demand specifics: percentages, counts, named technologies,
  concrete outcomes, time saved, people involved
- Keep the tone warm and conversational, like a supportive mentor — NOT a formal interviewer
- Naturally steer toward these five reflection areas without naming them explicitly:
  1. Key Learnings (what did you learn?)
  2. Mistakes & Lessons (what went wrong and what did you take from it?)
  3. Next Steps (what's your plan going forward?)
  4. Questions (what are you still unsure about?)
  5. What I Built (what tangible output did you create?)
- After 3-4 questions, wrap up naturally. Don't keep drilling forever.
- If the user's answer is already specific and quantified, acknowledge it and move on
- NEVER say "tell me more" — always ask for a SPECIFIC detail

EXAMPLES of good follow-up questions:
- "You mentioned working on the API — roughly how many endpoints did you build or modify?"
- "What was the hardest part of that Sprint Planning? Was there a specific decision that took longest?"
- "You said the meeting went well — did anything concrete get decided? Any action items assigned to you?"
- "About how long did the debugging take? What tool or approach finally helped you find the issue?"
''';
```

### System Instruction for Analysis
```dart
const _analysisSystemPrompt = '''
You analyze intern work reflections and extract structured metadata.

For each reflection, output:
- skillTags: 1-5 professional skill labels (e.g., "SQL", "Public Speaking", "Code Review",
  "Sprint Planning", "Debugging", "API Design"). Use title case. Be specific to the actual
  skills demonstrated, not generic.
- impactLevel: one of "low", "medium", "high", "critical" based on the scope and significance
  of the work described
- primaryCategory: the single best fit from ["key_learnings", "mistakes_and_lessons",
  "next_steps", "questions", "what_i_built"]
- secondaryCategories: 0-2 additional categories that also apply (can be empty array)

Guidelines:
- Prefer specific skill names over generic ones ("React Testing Library" > "Testing")
- Impact is about organizational impact, not personal difficulty
- If the reflection is vague, still do your best — tag based on what's there
''';
```

### Streaming Chat Display Widget
```dart
// Source: Custom implementation following firebase_ai streaming pattern
class DrilldownChat extends ConsumerStatefulWidget {
  final Entry entry;
  const DrilldownChat({super.key, required this.entry});

  @override
  ConsumerState<DrilldownChat> createState() => _DrilldownChatState();
}

class _DrilldownChatState extends ConsumerState<DrilldownChat> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  String _streamingText = '';
  bool _isStreaming = false;

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputController.clear();

    // Add user message to state
    ref.read(drilldownProvider(widget.entry.id).notifier).addUserMessage(text);

    setState(() {
      _isStreaming = true;
      _streamingText = '';
    });

    try {
      final chatSession = ref.read(chatSessionProvider(widget.entry.id));
      final stream = chatSession.sendMessageStream([Content.text(text)]);

      await for (final chunk in stream) {
        if (chunk.text != null) {
          setState(() {
            _streamingText += chunk.text!;
          });
          _scrollToBottom();
        }
      }

      // Streaming complete — add AI message to state
      ref.read(drilldownProvider(widget.entry.id).notifier)
          .addAiMessage(_streamingText);
    } catch (e) {
      ref.read(drilldownProvider(widget.entry.id).notifier)
          .setError('AI is temporarily unavailable. Try again in a moment.');
    } finally {
      setState(() {
        _isStreaming = false;
        _streamingText = '';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ... build method with ListView of message bubbles
}
```

### Convex Schema Extension
```typescript
// Source: Existing schema.ts — additions for AI metadata
entries: defineTable({
  userId: v.string(),
  body: v.string(),
  inputMethod: v.string(),
  calendarEventId: v.optional(v.string()),
  // NEW: AI metadata fields
  skillTags: v.optional(v.array(v.string())),          // ["SQL", "Public Speaking"]
  impactLevel: v.optional(v.string()),                  // "low" | "medium" | "high" | "critical"
  primaryCategory: v.optional(v.string()),              // "key_learnings" | "mistakes_and_lessons" | etc.
  secondaryCategories: v.optional(v.array(v.string())), // secondary categories
  aiDrilldownStatus: v.optional(v.string()),            // "pending" | "in_progress" | "complete" | "skipped"
  aiDrilldownMessages: v.optional(v.array(v.object({    // For resume support
    text: v.string(),
    isUser: v.boolean(),
  }))),
})
```

### ConvexHttpService Action Support
```dart
// Source: docs.convex.dev/http-api — extend existing service
// Add to ConvexHttpService class:
Future<dynamic> action({
  required String path,
  Map<String, dynamic> args = const {},
}) async {
  return _call(endpoint: 'action', path: path, args: args);
}
```

### Entry Model Extension
```dart
class Entry {
  // ... existing fields ...

  // NEW: AI metadata
  final List<String>? skillTags;
  final String? impactLevel;
  final String? primaryCategory;
  final List<String>? secondaryCategories;
  final String? aiDrilldownStatus; // 'pending' | 'in_progress' | 'complete' | 'skipped'

  // Updated fromJson to parse new fields
  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      // ... existing fields ...
      skillTags: (json['skillTags'] as List?)?.cast<String>(),
      impactLevel: json['impactLevel'] as String?,
      primaryCategory: json['primaryCategory'] as String?,
      secondaryCategories: (json['secondaryCategories'] as List?)?.cast<String>(),
      aiDrilldownStatus: json['aiDrilldownStatus'] as String?,
    );
  }
}
```

### Discretion Decision: Impact Level Visual Design
**Recommendation: Small colored dot indicator.** A single dot next to the timestamp on EntryCard, colored by impact level:
- Low: `colorScheme.outline` (subtle grey)
- Medium: `colorScheme.tertiary` (visible but not loud)
- High: `colorScheme.primary` (prominent)
- Critical: `colorScheme.error` (attention-grabbing)

This follows the existing card pattern (minimal, M3 themed) and doesn't compete with skill chips for visual space.

### Discretion Decision: Category Display on Cards
**Recommendation: Small text label above skill chips.** Primary category as a single-line label in `labelSmall` with `onSurfaceVariant` color. Secondary categories omitted from the card (visible only in entry detail). This keeps cards scannable.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| google_generative_ai package | firebase_ai package | May 2025 | google_generative_ai is deprecated; firebase_ai is the official replacement |
| Vertex AI for Firebase (firebase_vertexai) | Firebase AI Logic (firebase_ai) | May 2025 | Unified SDK for both Gemini Developer API and Vertex AI |
| Manual JSON parsing of AI output | responseSchema + responseMimeType | 2025 | Gemini guarantees schema-conformant JSON output |
| gemini-1.5-flash | gemini-2.5-flash / gemini-3-flash-preview | 2025-2026 | Newer models are faster, cheaper, more capable |

**Deprecated/outdated:**
- `google_generative_ai` package: Deprecated. Use `firebase_ai` instead.
- `firebase_vertexai` package: Deprecated. Replaced by unified `firebase_ai`.
- Manually constructing chat history arrays: Use `startChat()` which manages history automatically.

## Open Questions

1. **Firebase Project Setup**
   - What we know: The project needs a Firebase project. `flutterfire configure` generates the necessary config files.
   - What's unclear: Whether the user already has a Firebase project or needs to create one. Firebase console setup is interactive and cannot be fully automated.
   - Recommendation: Plan should include a Wave 0 / prerequisite step for Firebase project creation and `flutterfire configure`. This is a manual step the user must complete.

2. **Gemini Model Selection**
   - What we know: `gemini-2.5-flash` is current, fast, and cheap. `gemini-3-flash-preview` is newest but in preview.
   - What's unclear: Whether preview models are stable enough for production use.
   - Recommendation: Use `gemini-2.5-flash` for now. Easy to swap via a single string constant.

3. **Drilldown Messages Persistence Strategy**
   - What we know: Messages need to persist for resumability. Convex storage is the only option (no local DB).
   - What's unclear: Whether storing messages as a JSON array field on the entry document is efficient enough, or if a separate `drilldownMessages` table would be better.
   - Recommendation: Array field on the entry document. The array is small (6-8 messages max) and always accessed alongside the entry. A separate table adds unnecessary joins.

4. **Entry Body Merge Timing**
   - What we know: The merged body replaces the original entry body. This happens after drilldown completes.
   - What's unclear: Should the user see a preview/diff of the merged body before it replaces the original?
   - Recommendation: Show the merged body in a confirmation view before saving. If the user rejects it, keep the original body. This adds a step but prevents surprises.

## Sources

### Primary (HIGH confidence)
- [Firebase AI Logic - Get Started](https://firebase.google.com/docs/ai-logic/get-started) - Firebase project setup, model initialization, generateContent
- [Firebase AI Logic - Chat](https://firebase.google.com/docs/ai-logic/chat) - Multi-turn chat with startChat(), sendMessageStream(), history management
- [Firebase AI Logic - System Instructions](https://firebase.google.com/docs/ai-logic/system-instructions) - Content.system() syntax for steering model behavior
- [Firebase AI Logic - Structured Output](https://firebase.google.com/docs/ai-logic/generate-structured-output) - Schema.object(), responseMimeType, responseSchema for JSON output
- [Firebase AI Logic - Model Parameters](https://firebase.google.com/docs/ai-logic/model-parameters) - GenerationConfig with temperature, maxOutputTokens, topK, topP
- [Convex Actions](https://docs.convex.dev/functions/actions) - Action definition, ctx.runQuery/runMutation, "use node" runtime
- [Convex HTTP API](https://docs.convex.dev/http-api/) - /api/action endpoint for calling actions from Flutter
- [Convex Environment Variables](https://docs.convex.dev/production/environment-variables) - npx convex env set for API key storage

### Secondary (MEDIUM confidence)
- [firebase_ai pub.dev](https://pub.dev/packages/firebase_ai) - v3.9.0 confirmed, changelog reviewed
- [Flutter AI Toolkit](https://docs.flutter.dev/ai/ai-toolkit) - LlmChatView evaluated and rejected for this use case
- [@google/genai npm](https://www.npmjs.com/package/@google/genai) - Server-side alternative evaluated (v1.43.0)

### Tertiary (LOW confidence)
- Chat bubble implementation patterns from community blog posts - used for general UI approach only

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - firebase_ai v3.9.0 is well-documented, official Google SDK, verified via pub.dev and Firebase docs
- Architecture: MEDIUM-HIGH - Patterns follow established firebase_ai API (startChat, structured output). Custom state management is project-specific but follows existing Riverpod patterns.
- Pitfalls: HIGH - Firebase bootstrap requirement is the primary risk and is well-understood. System instruction quality is validated by official documentation examples.
- AI API behavior: MEDIUM - Structured output schema enforcement and streaming behavior verified via official docs. Actual quality of drilldown questions depends on prompt engineering.

**Research date:** 2026-03-04
**Valid until:** 2026-04-03 (30 days; firebase_ai stable, Gemini model names may update)
