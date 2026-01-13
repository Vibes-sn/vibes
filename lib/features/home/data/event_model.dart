class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.locationName,
    required this.price,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final DateTime eventDate;
  final String locationName;
  final num price;
  final String imageUrl;

  factory EventModel.fromMap(Map<String, dynamic> map) {
    final image = map['image_url'] as String?;
    return EventModel(
      id: map['id'] as String,
      title: map['title'] as String,
      eventDate: DateTime.parse(map['event_date'] as String),
      locationName: map['location_name'] as String,
      price: (map['price'] ?? 0) as num,
      imageUrl: image?.isNotEmpty == true
          ? image!
          : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900',
    );
  }
}
