/// A single Daily Canvas entry — a text or voice reflection created by a user.
///
/// Maps directly to a Convex `entries` document. The [fromJson] factory
/// handles the Convex JSON format where `_id` and `_creationTime` are
/// system fields and user fields are top-level.
class Entry {
  /// Convex document _id (e.g., "j57abc123...").
  final String id;

  /// Google ID of the owning user (matches AuthStateAuthenticated.userId).
  final String userId;

  /// Entry text content.
  final String body;

  /// How the entry was created: "text" or "voice".
  /// Used to display a mic badge on voice entries in the feed.
  final String inputMethod;

  /// Convex _creationTime — Unix milliseconds since epoch.
  final int creationTime;

  const Entry({
    required this.id,
    required this.userId,
    required this.body,
    required this.inputMethod,
    required this.creationTime,
  });

  /// Parses a Convex document JSON map into an [Entry].
  ///
  /// Expected keys: `_id`, `userId`, `body`, `inputMethod`, `_creationTime`.
  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['_id'] as String,
      userId: json['userId'] as String,
      body: json['body'] as String,
      inputMethod: json['inputMethod'] as String,
      creationTime: (json['_creationTime'] as num).toInt(),
    );
  }

  /// Convenience getter: creation time as a [DateTime] (local timezone).
  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(creationTime);

  /// Whether this entry was created via voice input.
  bool get isVoice => inputMethod == 'voice';

  @override
  String toString() => 'Entry(id: $id, body: "${body.length > 40 ? '${body.substring(0, 40)}...' : body}")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Entry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
