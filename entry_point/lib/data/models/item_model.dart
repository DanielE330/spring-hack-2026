import '../../domain/entities/item.dart';

class ItemModel {
  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.createdAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        imageUrl: json['image_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
      };

  Item toEntity() => Item(
        id: id,
        title: title,
        description: description,
        imageUrl: imageUrl,
        createdAt: createdAt,
      );
}

class ItemsPageModel {
  const ItemsPageModel({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
  });

  factory ItemsPageModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return ItemsPageModel(
      items: (json['items'] as List)
          .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int,
      perPage: meta['per_page'] as int,
      total: meta['total'] as int,
    );
  }

  final List<ItemModel> items;
  final int page;
  final int perPage;
  final int total;

  ItemsPage toEntity() => ItemsPage(
        items: items.map((e) => e.toEntity()).toList(),
        page: page,
        perPage: perPage,
        total: total,
      );
}
