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

    // CORRECTED CARD CODES - ALL UPPERCASE
    final Map<String, String> cardCodeMap = {
      'Ace': 'A', '2': '2', '3': '3', '4': '4', '5': '5', 
      '6': '6', '7': '7', '8': '8', '9': '9', '10': '0',
      'Jack': 'J', 'Queen': 'Q', 'King': 'K'
    };

    final Map<String, String> suitCodeMap = {
      'Hearts': 'H', 'Spades': 'S', 'Diamonds': 'D', 'Clubs': 'C'
    };

    for (final suit in suits) {
      for (final cardName in cardNames) {
        final cardCode = cardCodeMap[cardName]!;
        final suitCode = suitCodeMap[suit]!;
        
        // Using correct URL format with UPPERCASE suit codes
        final imageUrl = 'https://deckofcardsapi.com/static/img/${cardCode}${suitCode}.png';
        
        final card = {
          'name': cardName,
          'suit': suit,
          'image_url': imageUrl,
          'folder_id': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        };
        await db.insert('cards', card);
      }
    }
  }

  // RESET DATABASE METHOD - Call this to fix image URLs
  Future<void> resetDatabase() async {
    final db = await database;
    
    // Delete all existing data
    await db.delete('cards');
    await db.delete('folders');
    
    // Repopulate with correct data
    await _prepopulateFolders(db);
    await _prepopulateCards(db);
    
    print('Database reset complete with correct image URLs');
  }

  // ALTERNATIVE: Fix existing URLs without deleting data
  Future<void> fixImageUrls() async {
    final db = await database;
    final cards = await db.query('cards');
    
    final Map<String, String> cardCodeMap = {
      'Ace': 'A', '2': '2', '3': '3', '4': '4', '5': '5', 
      '6': '6', '7': '7', '8': '8', '9': '9', '10': '0',
      'Jack': 'J', 'Queen': 'Q', 'King': 'K'
    };

    final Map<String, String> suitCodeMap = {
      'Hearts': 'H', 'Spades': 'S', 'Diamonds': 'D', 'Clubs': 'C'
    };

    int updatedCount = 0;
    for (final card in cards) {
      final cardName = card['name'] as String;
      final suit = card['suit'] as String;
      final cardCode = cardCodeMap[cardName]!;
      final suitCode = suitCodeMap[suit]!;
      
      final correctUrl = 'https://deckofcardsapi.com/static/img/${cardCode}${suitCode}.png';
      
      await db.update(
        'cards',
        {'image_url': correctUrl},
        where: 'id = ?',
        whereArgs: [card['id']],
      );
      updatedCount++;
    }
    
    print('Fixed $updatedCount card image URLs');
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