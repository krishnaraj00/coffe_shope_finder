class CoffeeShop {
  final String id;
  final String name;
  final double lat;
  final double lng;

  CoffeeShop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'lat': lat,
    'lng': lng,
  };

  factory CoffeeShop.fromMap(Map<String, dynamic> m) => CoffeeShop(
    id: m['id'],
    name: m['name'],
    lat: m['lat'],
    lng: m['lng'],
  );
}
