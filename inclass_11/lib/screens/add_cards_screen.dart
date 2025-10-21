import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models.dart' as models;
import '../image_helper.dart';

class AddCardsScreen extends StatefulWidget {
  final models.Folder folder;
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
  List<models.CardModel> _availableCards = [];
  List<int> _selectedCardIds = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableCards();
  }

  Future<void> _loadAvailableCards() async {
    final cardsData = await _dbHelper.getCardsByFolder(null);
    setState(() {
      _availableCards = cardsData.map((data) => models.CardModel.fromMap(data)).toList();
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
    final canSelectMore = _selectedCardIds.length + widget.currentCardCount < 6;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Cards to ${widget.folder.name}'),
        backgroundColor: Colors.white,
        actions: [
          if (_selectedCardIds.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _addSelectedCards,
              icon: const Icon(Icons.add),
              label: Text('Add (${_selectedCardIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.blue[100]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select cards to add to ${widget.folder.name}',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$remainingSlots slots remaining • ${_selectedCardIds.length} selected',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator
          if (widget.currentCardCount > 0)
            LinearProgressIndicator(
              value: widget.currentCardCount / 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),

          // Cards grid
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
                        SizedBox(height: 8),
                        Text(
                          'All cards are already in folders',
                          style: TextStyle(color: Colors.grey),
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
                          elevation: isSelected ? 8 : 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? const BorderSide(color: Colors.blue, width: 3)
                                : canSelectMore
                                    ? BorderSide.none
                                    : const BorderSide(color: Colors.grey, width: 1),
                          ),
                          color: canSelectMore ? null : Colors.grey[100],
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: ImageHelper.networkImageWithFallback(
                                      card.imageUrl,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      card.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: canSelectMore ? Colors.black : Colors.grey,
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
                              if (!canSelectMore && !isSelected)
                                const Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.lock, size: 12, color: Colors.white),
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