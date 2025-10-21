import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageHelper {
  static Widget networkImageWithFallback(
    String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(url),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
    );
  }

  static Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.photo_library,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }

  static Widget _buildErrorWidget(String url) {
    // Extract card info from URL to display as fallback
    String cardInfo = _extractCardInfoFromUrl(url);
    
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.credit_card,
              color: Colors.grey,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              cardInfo,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _extractCardInfoFromUrl(String url) {
    try {
      // Extract card info from URL like "https://deckofcardsapi.com/static/img/AH.png"
      final filename = url.split('/').last;
      final cardCode = filename.split('.').first;
      if (cardCode.length == 2) {
        final valueCode = cardCode[0];
        final suitCode = cardCode[1];
        
        final valueMap = {
          'A': 'Ace', '2': '2', '3': '3', '4': '4', '5': '5',
          '6': '6', '7': '7', '8': '8', '9': '9', '0': '10',
          'J': 'Jack', 'Q': 'Queen', 'K': 'King'
        };
        
        final suitMap = {
          'H': 'Hearts', 'S': 'Spades', 'D': 'Diamonds', 'C': 'Clubs'
        };
        
        final cardValue = valueMap[valueCode] ?? valueCode;
        final cardSuit = suitMap[suitCode] ?? suitCode;
        
        return '$cardValue\n$cardSuit';
      }
    } catch (e) {
      // If parsing fails, return generic text
    }
    return 'Card\nImage';
  }

  // Alternative local asset images as fallback
  static String getLocalAssetPath(String cardName, String suit) {
    return 'assets/cards/${cardName.toLowerCase()}_of_${suit.toLowerCase()}.png';
  }
}