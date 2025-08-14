import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'Model/Db_helper.dart';
import 'View/fav_screen.dart';
import 'View/map_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nearest Coffee Shop Finder',
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => MapScreen()),
        GetPage(name: '/favorites', page: () => FavoritesScreen()),
      ],
    );
  }
}
