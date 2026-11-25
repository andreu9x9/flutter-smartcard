class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;

  const UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}

class ShoppingItem {
  final int? id;
  final int userId;
  final String title;
  final String category;
  final double plannedQty;
  final double actualQty;
  final String unit;
  final double price;
  final bool isBought;

  const ShoppingItem({
    this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.plannedQty,
    required this.actualQty,
    required this.unit,
    required this.price,
    this.isBought = false,
  });

  double get plannedTotal => plannedQty * price;
  double get actualTotal => actualQty * price;

  ShoppingItem copyWith({
    int? id,
    int? userId,
    String? title,
    String? category,
    double? plannedQty,
    double? actualQty,
    String? unit,
    double? price,
    bool? isBought,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      plannedQty: plannedQty ?? this.plannedQty,
      actualQty: actualQty ?? this.actualQty,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      isBought: isBought ?? this.isBought,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'title': title,
      'category': category,
      'planned_qty': plannedQty,
      'actual_qty': actualQty,
      'unit': unit,
      'price': price,
      'is_bought': isBought ? 1 : 0,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      category: map['category'] as String,
      plannedQty: (map['planned_qty'] as num).toDouble(),
      actualQty: (map['actual_qty'] as num).toDouble(),
      unit: map['unit'] as String,
      price: (map['price'] as num).toDouble(),
      isBought: (map['is_bought'] as int) == 1,
    );
  }
}

class PriceHistory {
  final int? id;
  final int itemId;
  final double price;
  final DateTime recordedAt;

  const PriceHistory({
    this.id,
    required this.itemId,
    required this.price,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_id': itemId,
      'price': price,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  factory PriceHistory.fromMap(Map<String, dynamic> map) {
    return PriceHistory(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      price: (map['price'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }
}