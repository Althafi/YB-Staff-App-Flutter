class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    this.category,
    required this.price,
    this.unit,
  });

  final int id;
  final String name;
  final String? category;
  final double price;
  final String? unit;
}
