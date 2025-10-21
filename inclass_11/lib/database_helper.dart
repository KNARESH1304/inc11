import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'card_organizer.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT NOT NULL,
        folder_id INTEGER,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders (id)
      )
    ''');

    // Prepopulate folders
    await _prepopulateFolders(db);
    // Prepopulate cards
    await _prepopulateCards(db);
  }

  Future<void> _prepopulateFolders(Database db) async {
    final folders = [
      {
        'name': 'Hearts',
        'color': '#FF5252',
        'icon': '❤️',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'name': 'Spades',
        'color': '#424242',
        'icon': '♠️',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'name': 'Diamonds',
        'color': '#FF4081',
        'icon': '♦️',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'name': 'Clubs',
        'color': '#388E3C',
        'icon': '♣️',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (final folder in folders) {
      await db.insert('folders', folder);
    }
  }

  Future<void> _prepopulateCards(Database db) async {
    final suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    final cardNames = [
      'Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'
    ];

    for (final suit in suits) {
      for (int i = 0; i < cardNames.length; i++) {
        final cardName = cardNames[i];
        final suitInitial = suit.substring(0, 1).toLowerCase();
        final imageName = cardName.toLowerCase() == 'ace' ? 'A' : 
                         cardName.toLowerCase() == 'jack' ? 'J' :
                         cardName.toLowerCase() == 'queen' ? 'Q' :
                         cardName.toLowerCase() == 'king' ? 'K' : cardName;
        
        final card = {
          'name': cardName,
          'suit': suit,
          'image_url': 'https://deckofcardsapi.com/static/img/${imageName}${suitInitial}.png',
          'folder_id': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        };
        await db.insert('cards', card);
      }
    }
  }

  // Folder operations
  Future<List<Map<String, dynamic>>> getFolders() async {
    final db = await database;
    return await db.query('folders', orderBy: 'created_at DESC');
  }

  Future<int> updateFolder(int id, String name) async {
    final db = await database;
    return await db.update(
      'folders',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    await db.update(
      'cards',
      {'folder_id': null},
      where: 'folder_id = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Card operations
  Future<List<Map<String, dynamic>>> getCardsByFolder(int? folderId) async {
    final db = await database;
    if (folderId == null) {
      return await db.query('cards', where: 'folder_id IS NULL');
    }
    return await db.query(
      'cards',
      where: 'folder_id = ?',
      whereArgs: [folderId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllCards() async {
    final db = await database;
    return await db.query('cards');
  }

  Future<int> updateCardFolder(int cardId, int? folderId) async {
    final db = await database;
    return await db.update(
      'cards',
      {'folder_id': folderId},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  Future<int> getCardCountInFolder(int folderId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM cards WHERE folder_id = ?',
      [folderId],
    );
    return result.first['count'] as int;
  }

  Future<int> deleteCard(int cardId) async {
    final db = await database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}