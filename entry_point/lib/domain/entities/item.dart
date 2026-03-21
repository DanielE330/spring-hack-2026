import 'package:equatable/equatable.dart';

class Item extends Equatable {
  const Item({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;

  Item copyWith({
    int? id,
    String? title,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
  }) =>
      Item(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, title, description, imageUrl, createdAt];
}

class ItemsPage extends Equatable {
  const ItemsPage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
  });

  final List<Item> items;
  final int page;
  final int perPage;
  final int total;

  bool get hasMore => (page * perPage) < total;

  @override
  List<Object?> get props => [items, page, perPage, total];
}
