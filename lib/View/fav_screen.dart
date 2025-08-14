import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Controller/fav_controller.dart';


class FavoritesScreen extends StatelessWidget {
  final FavoritesController favC = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorites')),
      body: Obx(() {
        final list = favC.favorites;
        if (list.isEmpty) return Center(child: Text('No favorites yet'));
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => Divider(height: 1),
          itemBuilder: (context, i) {
            final s = list[i];
            return ListTile(
              title: Text(s.name),
              subtitle: Text('Lat: ${s.lat}, Lng: ${s.lng}'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await favC.remove(s.id);
                  Get.snackbar('Removed', '${s.name} removed');
                },
              ),
            );
          },
        );
      }),
    );
  }
}
