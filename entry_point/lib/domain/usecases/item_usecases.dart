import 'dart:io';
import '../entities/item.dart';
import '../repositories/item_repository.dart';

class GetItemsUseCase {
  const GetItemsUseCase(this._repo);

  final ItemRepository _repo;

  Future<ItemsPage> call({
    int page = 1,
    int perPage = 20,
    String? query,
  }) =>
      _repo.getItems(page: page, perPage: perPage, query: query);
}

class GetItemUseCase {
  const GetItemUseCase(this._repo);

  final ItemRepository _repo;

  Future<Item> call(int id) => _repo.getItem(id);
}

class CreateItemUseCase {
  const CreateItemUseCase(this._repo);

  final ItemRepository _repo;

  Future<Item> call({
    required String title,
    required String description,
    File? image,
    void Function(int sent, int total)? onProgress,
  }) =>
      _repo.createItem(
        title: title,
        description: description,
        image: image,
        onProgress: onProgress,
      );
}

class UpdateItemUseCase {
  const UpdateItemUseCase(this._repo);

  final ItemRepository _repo;

  Future<Item> call({
    required int id,
    required String title,
    required String description,
  }) =>
      _repo.updateItem(id: id, title: title, description: description);
}

class DeleteItemUseCase {
  const DeleteItemUseCase(this._repo);

  final ItemRepository _repo;

  Future<void> call(int id) => _repo.deleteItem(id);
}
