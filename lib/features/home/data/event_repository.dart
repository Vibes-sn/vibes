import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibes/features/home/data/event_model.dart';

class EventRepository {
  EventRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<EventModel>> fetchPublishedEvents() async {
    final response = await _client
        .from('events')
        .select()
        .eq('is_published', true)
        .order('event_date', ascending: true);

    final data = response as List<dynamic>;
    return data
        .map((e) => EventModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
