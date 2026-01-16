class Event {
  const Event({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.locationName,
    required this.price,
    required this.capacity,
    required this.imageUrl,
    required this.category,
    required this.isPublished,
    required this.createdAt,
  });

  static const table = 'events';
  static const colId = 'id';
  static const colHostId = 'host_id';
  static const colTitle = 'title';
  static const colDescription = 'description';
  static const colEventDate = 'event_date';
  static const colLocationName = 'location_name';
  static const colPrice = 'price';
  static const colCapacity = 'capacity';
  static const colImageUrl = 'image_url';
  static const colCategory = 'category';
  static const colIsPublished = 'is_published';
  static const colCreatedAt = 'created_at';

  final String id;
  final String? hostId;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String locationName;
  final num price;
  final int? capacity;
  final String? imageUrl;
  final String? category;
  final bool isPublished;
  final DateTime createdAt;

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map[colId] as String,
      hostId: map[colHostId] as String?,
      title: map[colTitle] as String? ?? '',
      description: map[colDescription] as String?,
      eventDate: DateTime.parse(map[colEventDate] as String),
      locationName: map[colLocationName] as String? ?? '',
      price: (map[colPrice] ?? 0) as num,
      capacity: map[colCapacity] as int?,
      imageUrl: map[colImageUrl] as String?,
      category: map[colCategory] as String?,
      isPublished: map[colIsPublished] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map[colCreatedAt] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
