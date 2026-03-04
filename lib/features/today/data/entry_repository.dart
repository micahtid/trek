import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/convex/convex_service.dart';
import '../domain/entry.dart';

/// Bridges Convex CRUD operations for entries to Dart async methods.
///
/// All methods call [ConvexService.instance] mutation/query wrappers.
/// Convex returns JSON strings which are decoded and mapped to [Entry] objects.
class EntryRepository {
  /// Creates a new entry and returns the Convex document _id.
  Future<String> createEntry({
    required String userId,
    required String body,
    required String inputMethod,
  }) async {
    final result = await ConvexService.instance.mutation(
      name: 'entries:createEntry',
      args: {
        'userId': userId,
        'body': body,
        'inputMethod': inputMethod,
      },
    );
    // Convex returns the _id as a JSON string — decode it
    return _parseId(result);
  }

  /// Updates the body text of an existing entry.
  Future<void> updateEntry({
    required String entryId,
    required String body,
  }) async {
    await ConvexService.instance.mutation(
      name: 'entries:updateEntry',
      args: {
        'entryId': entryId,
        'body': body,
      },
    );
  }

  /// Deletes an entry by its Convex document _id.
  Future<void> deleteEntry(String entryId) async {
    await ConvexService.instance.mutation(
      name: 'entries:deleteEntry',
      args: {
        'entryId': entryId,
      },
    );
  }

  /// Full-text search across entry bodies for a given user.
  ///
  /// Supports optional [startDate] and [endDate] (Unix ms) for date range filtering.
  /// Returns up to 50 results ordered by search relevance.
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

    final result = await ConvexService.instance.query(
      'entries:searchEntries',
      args,
    );
    return _parseEntryList(result);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses a Convex JSON result string into a list of [Entry] objects.
  List<Entry> _parseEntryList(String jsonString) {
    final decoded = json.decode(jsonString);
    if (decoded is List) {
      return decoded
          .cast<Map<String, dynamic>>()
          .map(Entry.fromJson)
          .toList();
    }
    return [];
  }

  /// Parses a Convex document ID from a mutation result.
  String _parseId(String result) {
    try {
      final decoded = json.decode(result);
      if (decoded is String) return decoded;
      return result;
    } catch (_) {
      return result;
    }
  }
}

/// Riverpod provider for [EntryRepository] — simple singleton, no dependencies.
final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository();
});
