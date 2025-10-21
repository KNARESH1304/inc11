class CardModel {
  final int id;
  final String name;
  final String suit;
  final String imageUrl;
  final int? folderId;
  final DateTime createdAt;

  CardModel({
    required this.id,
    required this.name,
    required this.suit,
    required this.imageUrl,
    this.folderId,
    required this.createdAt,
  });

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      name: map['name'],
      suit: map['suit'],
      imageUrl: map['image_url'],
      folderId: map['folder_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  String get fullName => '$name of $suit';
}

class Folder {
  final int id;
  final String name;
  final String color;
  final String icon;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      icon: map['icon'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}