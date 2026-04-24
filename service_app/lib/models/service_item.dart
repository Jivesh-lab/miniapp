class ServiceItem {
  final String id;
  final String name;

  const ServiceItem({
    required this.id,
    required this.name,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}