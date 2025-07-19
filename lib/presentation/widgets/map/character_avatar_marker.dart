import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CharacterAvatarMarker {
  static final List<String> _avatarEmojis = [
    '🧑‍🎓', '👩‍🎓', '👨‍🎓', '🧑‍💼', '👩‍💼', '👨‍💼',
    '🧑‍🔬', '👩‍🔬', '👨‍🔬', '🧑‍🎨', '👩‍🎨', '👨‍🎨',
    '🧑‍💻', '👩‍💻', '👨‍💻', '🧑‍⚕️', '👩‍⚕️', '👨‍⚕️',
    '🧑‍🏫', '👩‍🏫', '👨‍🏫', '🧑‍🎤', '👩‍🎤', '👨‍🎤',
  ];

  static final List<Color> _borderColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.cyan,
    Colors.teal,
    Colors.indigo,
  ];

  // Generate character avatar for driver
  static String getCharacterForDriver(String driverId) {
    final index = driverId.hashCode % _avatarEmojis.length;
    return _avatarEmojis[index.abs()];
  }

  // Generate border color for driver
  static Color getBorderColorForDriver(String driverId) {
    final index = driverId.hashCode % _borderColors.length;
    return _borderColors[index.abs()];
  }

  // Generate hue for marker color
  static double getHueForDriver(String driverId) {
    final color = getBorderColorForDriver(driverId);
    // Convert color to HSV and return hue
    HSVColor hsv = HSVColor.fromColor(color);
    return hsv.hue;
  }

  // Create custom marker with character avatar (Snapchat-style)
  static Future<BitmapDescriptor> createCharacterMarker({
    required String driverId,
    required String driverName,
    required double price,
    required int availableSeats,
    bool isOnline = true,
  }) async {
    const int markerSize = 60;
    
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    final Paint circlePaint = Paint()
      ..color = isOnline ? getBorderColorForDriver(driverId) : Colors.grey
      ..style = PaintingStyle.fill;
    
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Draw shadow
    canvas.drawCircle(
      const Offset(markerSize / 2 + 1, markerSize / 2 + 1),
      (markerSize / 2) - 5,
      shadowPaint,
    );

    // Draw main circle
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2),
      (markerSize / 2) - 5,
      circlePaint,
    );

    // Draw white border
    canvas.drawCircle(
      const Offset(markerSize / 2, markerSize / 2),
      (markerSize / 2) - 5,
      borderPaint,
    );

    // Draw character emoji
    final textPainter = TextPainter(
      text: TextSpan(
        text: getCharacterForDriver(driverId),
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (markerSize - textPainter.width) / 2,
        (markerSize - textPainter.height) / 2 - 5,
      ),
    );

    // Draw price tag (like Snapchat's info bubbles)
    if (isOnline) {
      final priceRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(markerSize * 0.1, markerSize * 0.75, markerSize * 0.8, 18),
        const Radius.circular(9),
      );
      
      final pricePaint = Paint()
        ..color = Colors.black.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(priceRect, pricePaint);
      
      final priceTextPainter = TextPainter(
        text: TextSpan(
          text: 'R${price.toStringAsFixed(0)} • $availableSeats seats',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      
      priceTextPainter.layout();
      priceTextPainter.paint(
        canvas,
        Offset(
          (markerSize - priceTextPainter.width) / 2,
          markerSize * 0.75 + 4,
        ),
      );
    }

    // Convert to image
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(markerSize, markerSize);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  // Create pulsing effect for active drivers
  static Widget createPulsingAvatar({
    required String driverId,
    required VoidCallback onTap,
    required bool isOnline,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring effect (like Snapchat)
          if (isOnline)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 1500),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: getBorderColorForDriver(driverId).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          
          // Main avatar circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? getBorderColorForDriver(driverId) : Colors.grey,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                getCharacterForDriver(driverId),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          
          // Online indicator dot
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Create floating driver info card (Snapchat-style)
  static Widget createDriverInfoCard({
    required String driverName,
    required String university,
    required double rating,
    required int totalRides,
    required double price,
    required int availableSeats,
    required VoidCallback onBookRide,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text('🧑‍🎓', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      university,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          ' $rating • $totalRides rides',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'R${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                '$availableSeats seats available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBookRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Book Ride',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 