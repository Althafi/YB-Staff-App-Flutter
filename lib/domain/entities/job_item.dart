class JobItem {
  const JobItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.description,
  });

  final int id;
  final String name;
  final double quantity;
  final double price;
  final double subtotal;
  final String? description;

  JobItem copyWith({
    int? id,
    String? name,
    double? quantity,
    double? price,
    double? subtotal,
    String? description,
  }) {
    return JobItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          quantity == other.quantity &&
          price == other.price;

  @override
  int get hashCode => Object.hash(id, name, quantity, price);
}
