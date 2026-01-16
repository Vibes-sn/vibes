import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/core/models/profile.dart';

class DatabaseService {
  DatabaseService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<Profile?> watchProfile(String userId) {
    return _client
        .from(Profile.table)
        .stream(primaryKey: [Profile.colId])
        .eq(Profile.colId, userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return Profile.fromMap(rows.first);
        });
  }

  Stream<String> watchRole(String userId) {
    return watchProfile(
      userId,
    ).map((profile) => profile?.role ?? 'viber').distinct();
  }

  Stream<bool> watchVerified(String userId) {
    return watchProfile(
      userId,
    ).map((profile) => profile?.isVerified ?? false).distinct();
  }

  Future<Profile?> fetchProfile(String userId) async {
    final data = await _client
        .from(Profile.table)
        .select()
        .eq(Profile.colId, userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromMap(data);
  }
}
