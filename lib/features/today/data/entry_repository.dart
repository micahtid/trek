import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/convex/convex_service.dart';
import '../domain/entry.dart';

/// Bridges Convex CRUD operations for entries to Dart async methods.
///
/// All methods call [ConvexHttpService.instance] which uses the Convex HTTP API.
class EntryRepository {
  /// Creates a new entry and returns the Convex document _id.
  ///
  /// If [calendarEventId] is provided, the entry is linked to a calendar
  /// event as a reflection (Phase 3).
  Future<String> createEntry({
    required String userId,
    required String body,
    required String inputMethod,
    String? calendarEventId,
  }) async {
    final args = <String, dynamic>{
      'userId': userId,
      'body': body,
      'inputMethod': inputMethod,
    };
    if (calendarEventId != null) {
      args['calendarEventId'] = calendarEventId;
    }

    final result = await ConvexHttpService.instance.mutation(
      path: 'entries:createEntry',
      args: args,
    );
    return result is String ? result : result.toString();
  }

  /// Updates the body text of an existing entry.
  Future<void> updateEntry({
    required String entryId,
    required String body,
  }) async {
    await ConvexHttpService.instance.mutation(
      path: 'entries:updateEntry',
      args: {
        'entryId': entryId,
        'body': body,
      },
    );
  }

  /// Deletes an entry by its Convex document _id.
  Future<void> deleteEntry(String entryId) async {
    await ConvexHttpService.instance.mutation(
      path: 'entries:deleteEntry',
      args: {
        'entryId': entryId,
      },
    );
  }

  /// Full-text search across entry bodies for a given user.
  Future<List<Entry>> searchEntries({
    required String userId,
    required String searchText,
    int? startDate,
    int? endDate,
  }) async {
    final args = <String, dynamic>{
      'userId': userId,
      'searchText': searchText,
    };
    if (startDate != null) args['startDate'] = startDate;
    if (endDate != null) args['endDate'] = endDate;

    final result = await ConvexHttpService.instance.query(
      path: 'entries:searchEntries',
      args: args,
    );

    if (result is List) {
      return result
          .cast<Map<String, dynamic>>()
          .map(Entry.fromJson)
          .toList();
    }
    return [];
  }
}

/// Riverpod provider for [EntryRepository] — simple singleton, no dependencies.
final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository();
});
