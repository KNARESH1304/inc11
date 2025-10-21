import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart';

class AddCardsScreen extends StatefulWidget {
  final Folder folder;
  final int currentCardCount;

  const AddCardsScreen({
    super.key,
    required this.folder,
    required this.currentCardCount,
  });

  @override
  State<AddCardsScreen> createState() => _AddCardsScreenState();
}

class _AddCardsScreenState extends State<AddCardsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<CardModel> _availableCards = [];
  List<int> _selectedCardIds = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableCards();
  }

  Future<void> _loadAvailableCards() async {
    final cardsData = await _dbHelper.getCardsByFolder(null);
    setState(() {
      _availableCards = cardsData.map((data) => CardModel.fromMap(data)).toList();
    });
  }

  void _toggleCardSelection(int cardId) {
    setState(() {
      if (_selectedCardIds.contains(cardId)) {
        _selectedCardIds.remove(cardId);
      } else {
        if (_selectedCardIds.length + widget.currentCardCount < 6) {
          _selectedCardIds.add(cardId);
        } else {
          _showCardLimitError();
        }
      }
    });
  }

  void _showCardLimitError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.folder.name} folder can only hold 6 cards total.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _addSelectedCards() async {
    for (final cardId in _selectedCardIds) {
      await _dbHelper.updateCardFolder(cardId, widget.folder.id);
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final remainingSlots = 6 - widget.currentCardCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Cards to ${widget.folder.name}'),
        backgroundColor: Colors.white,
        actions: [
          if (_selectedCardIds.isNotEmpty)
            TextButton(
              onPressed: _addSelectedCards,
              child: Text(
                'Add (${_selectedCardIds.length})',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select cards to add ($remainingSlots slots remaining)',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _availableCards.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No available cards',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _availableCards.length,
                    itemBuilder: (context, index) {
                      final card = _availableCards[index];
                      final isSelected = _selectedCardIds.contains(card.id);

                      return GestureDetector(
                        onTap: () => _toggleCardSelection(card.id),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? const BorderSide(color: Colors.blue, width: 3)
                                : BorderSide.none,
                          ),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(card.imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      card.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.blue,
                                    child: Icon(Icons.check, size: 16, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}