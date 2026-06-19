import 'package:yb_staff_app/domain/entities/job_item.dart';

class JobItemModel {
  const JobItemModel({
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

  factory JobItemModel.fromJson(Map<String, dynamic> json) {
    final quantity = (json['quantity'] as num?)?.toDouble() ??
        (json['qty'] as num?)?.toDouble() ??
        1.0;
    final price = (json['unit_price'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0;
    // Use API-provided subtotal directly; formula varies (area_size * qty * price etc.)
    final subtotal = (json['subtotal'] as num?)?.toDouble() ??
        (json['estimated_price'] as num?)?.toDouble() ??
        quantity * price;
    return JobItemModel(
      id: json['id'] as int? ?? 0,
      name: json['item_name'] as String? ?? json['name'] as String? ?? '',
      quantity: quantity,
      price: price,
      subtotal: subtotal,
      description: json['item_category_name'] as String? ??
          json['description'] as String?,
    );
  }

  JobItem toEntity() => JobItem(
        id: id,
        name: name,
        quantity: quantity,
        price: price,
        subtotal: subtotal,
        description: description,
      );
}
