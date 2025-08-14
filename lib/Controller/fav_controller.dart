import 'package:get/get.dart';
import '../Model/Db_helper.dart';
import '../Model/model_class.dart';


class FavoritesController extends GetxController {
  var favorites = <CoffeeShop>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final list = await DBHelper.allFavorites();
    favorites.assignAll(list);
  }

  Future<void> add(CoffeeShop s) async {
    await DBHelper.addFavorite(s);
    favorites.add(s);
  }

  Future<void> remove(String id) async {
    await DBHelper.removeFavorite(id);
    favorites.removeWhere((e) => e.id == id);
  }

  bool contains(String id) => favorites.any((e) => e.id == id);
}
