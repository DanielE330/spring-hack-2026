import 'dart:io';
import '../entities/item.dart';

abstract interface class ItemRepository {
  Future<ItemsPage> getItems({
    int page = 1,
    int perPage = 20,
    String? query,
  });

  Future<Item> getItem(int id);

  Future<Item> createItem({
    required String title,
    required String description,
    File? image,
    void Function(int sent, int total)? onProgress,
  });

  Future<Item> updateItem({
    required int id,
    required String title,
    required String description,
  });

  Future<void> deleteItem(int id);
}
