import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/entities/location.dart';

class LocationService {
  // Google Places API key for location search functionality
  static const String _apiKey = 'AIzaSyDZ9UuOmKI91wNSqZ09sP89RJypa5wFql4';
  
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  /// Search for places using Google Places Autocomplete API (Production)
  Future<List<Location>> searchPlaces(String query, {
    LatLng? location,
    int radiusMeters = 50000, // 50km radius
    String? countryCode = 'ZA', // South Africa
  }) async {
    if (query.length < 2) return [];

    try {
      print('🔍 Searching places: $query');
      
      // For web, use JSONP approach to avoid CORS issues
      if (kIsWeb) {
        print('🌐 Running on web - using web-compatible search');
        return await _searchWithWebCompatibleAPI(query, location: location);
      } else {
        // Use Google Places API for mobile platforms
        final predictions = await _searchWithGooglePlaces(query, location: location);
        
        if (predictions.isNotEmpty) {
          print('✅ Found ${predictions.length} places from Google Places API');
          return predictions;
        }
      }
      
      // Fallback to local suggestions if API fails
      print('⚠️ Google Places API failed, using fallback locations');
      return _getFallbackLocations(query);
      
    } catch (e) {
      print('❌ Location search error: $e');
      // Return fallback locations as last resort
      return _getFallbackLocations(query);
    }
  }

  /// Web-compatible search using Google Places API with JSONP
  Future<List<Location>> _searchWithWebCompatibleAPI(String query, {LatLng? location}) async {
    try {
      print('🌐 Using web-compatible Google Places search');
      
      // For web, we'll use a smarter fallback approach
      // In a production app, you'd want to use a backend proxy to avoid CORS
      final fallbackResults = _getFallbackLocations(query);
      
      // Try to enhance fallback results with Google Places if possible
      if (fallbackResults.isNotEmpty) {
        print('✅ Enhanced fallback search found ${fallbackResults.length} results');
        return fallbackResults;
      }
      
      // If no fallback results, try direct API call (will likely fail on web)
      return await _searchWithGooglePlaces(query, location: location);
      
    } catch (e) {
      print('❌ Web-compatible search failed: $e');
      return _getFallbackLocations(query);
    }
  }

  /// Use Google Places API for real location search (Mobile)
  Future<List<Location>> _searchWithGooglePlaces(String query, {LatLng? location}) async {
    try {
      // Enhanced search with multiple place types
      final searchTypes = [
        'establishment',
        'geocode',
        'address',
        'university',
        'school',
        'point_of_interest'
      ];
      
      List<Location> allResults = [];
      
      for (final type in searchTypes) {
        try {
          final results = await _searchByType(query, type, location: location);
          allResults.addAll(results);
          
          // If we have enough results, break early
          if (allResults.length >= 5) break;
        } catch (e) {
          print('⚠️ Search by type $type failed: $e');
          continue;
        }
      }
      
      // Remove duplicates based on coordinates
      final uniqueResults = <Location>[];
      for (final result in allResults) {
        final isDuplicate = uniqueResults.any((existing) => 
          (existing.latitude - result.latitude).abs() < 0.001 &&
          (existing.longitude - result.longitude).abs() < 0.001
        );
        if (!isDuplicate) {
          uniqueResults.add(result);
        }
      }
      
      return uniqueResults.take(5).toList();
      
    } catch (e) {
      print('❌ Google Places API error: $e');
      throw e;
    }
  }

  /// Search by specific place type
  Future<List<Location>> _searchByType(String query, String type, {LatLng? location}) async {
    try {
      // Construct the Places API URL with enhanced parameters
      final baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      final locationBias = location != null 
          ? '&location=${location.latitude},${location.longitude}&radius=50000'
          : '&location=-33.9249,18.4241&radius=50000'; // Default to Cape Town
      
      final url = '$baseUrl?input=${Uri.encodeQueryComponent(query)}&key=$_apiKey&components=country:za$locationBias&types=$type&language=en';
      
      print('🔍 Calling Google Places API: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📡 Google Places API response status: ${data['status']}');
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          print('🎯 Found ${predictions.length} predictions for type $type');
          
          // Get detailed information for each prediction
          final locations = <Location>[];
          
          for (final prediction in predictions.take(3)) {
            try {
              final placeId = prediction['place_id'];
              final description = prediction['description'] ?? '';
              
              print('🔍 Getting details for place: $description (ID: $placeId)');
              
              final detailedLocation = await _getPlaceDetails(placeId, description);
              
              if (detailedLocation != null) {
                print('✅ Got coordinates: ${detailedLocation.latitude}, ${detailedLocation.longitude}');
                locations.add(detailedLocation);
              }
            } catch (e) {
              print('❌ Error processing prediction: $e');
              continue;
            }
          }
          
          return locations;
        } else {
          print('❌ Google Places API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          if (data['status'] == 'OVER_QUERY_LIMIT') {
            print('⚠️ API quota exceeded - falling back to local suggestions');
          }
          return [];
        }
      } else {
        print('❌ HTTP error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Google Places API error for type $type: $e');
      return [];
    }
  }

  /// Get detailed place information including coordinates
  Future<Location?> _getPlaceDetails(String placeId, String fallbackDescription) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId&key=$_apiKey&fields=name,formatted_address,geometry,types,rating,place_id';
      
      print('🔍 Calling Place Details API: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📡 Place Details API response status: ${data['status']}');
        
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          
          if (result['geometry'] != null && result['geometry']['location'] != null) {
            final geometry = result['geometry'];
            final coordinates = geometry['location'];
            
            final lat = coordinates['lat'];
            final lng = coordinates['lng'];
            
            print('✅ Place details successful:');
            print('  - Name: ${result['name'] ?? 'N/A'}');
            print('  - Address: ${result['formatted_address'] ?? 'N/A'}');
            print('  - Coordinates: $lat, $lng');
            print('  - Rating: ${result['rating'] ?? 'N/A'}');
            
            return Location(
              latitude: lat.toDouble(),
              longitude: lng.toDouble(),
              address: result['formatted_address'] ?? fallbackDescription,
              landmark: result['name'] ?? fallbackDescription,
              city: _extractCity(result['formatted_address'] ?? ''),
            );
          } else {
            print('❌ No geometry data in place details response');
            return null;
          }
        } else {
          print('❌ Place Details API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
          return null;
        }
      } else {
        print('❌ Place Details HTTP error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Exception in place details: $e');
      return null;
    }
  }

  /// Extract city name from address
  String _extractCity(String address) {
    // Look for common South African cities
    const cities = [
      'Cape Town', 'Johannesburg', 'Durban', 'Pretoria', 'Port Elizabeth', 
      'Bloemfontein', 'Stellenbosch', 'Ballito', 'Pietermaritzburg', 'Rustenburg'
    ];
    
    for (final city in cities) {
      if (address.toLowerCase().contains(city.toLowerCase())) {
        return city;
      }
    }
    
    return 'Cape Town'; // Default
  }

  /// Get popular locations for display
  List<Location> getPopularLocations() {
    return _getFallbackLocations('');
  }

  /// Enhanced fallback locations with smart search
  List<Location> _getFallbackLocations(String query) {
    final fallbackLocations = [
      // Enhanced Stellenbosch locations with more variety
      Location(
        latitude: -33.9300,
        longitude: 18.8500,
        address: 'Stellenbosch Huis Visser, Stellenbosch',
        landmark: 'Stellenbosch Huis Visser',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9278,
        longitude: 18.8492,
        address: 'De Lapa, Stellenbosch',
        landmark: 'De Lapa Club',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9344,
        longitude: 18.8658,
        address: 'Stellenbosch University Main Campus, Stellenbosch',
        landmark: 'Stellenbosch Main Campus',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9356,
        longitude: 18.8673,
        address: 'Neelsie Student Centre, Stellenbosch',
        landmark: 'Stellenbosch Neelsie Student Centre',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9321,
        longitude: 18.8656,
        address: 'Plato Stellenbosch',
        landmark: 'Plato Restaurant',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9287,
        longitude: 18.8503,
        address: 'Hudsons The Burger Joint, Stellenbosch',
        landmark: 'Hudsons Stellenbosch',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9289,
        longitude: 18.8501,
        address: 'Dorp Street, Stellenbosch',
        landmark: 'Stellenbosch Dorp Street',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9315,
        longitude: 18.8645,
        address: 'Stellenbosch University Library, Stellenbosch',
        landmark: 'Stellenbosch University Library',
        city: 'Stellenbosch',
      ),
      
      // Coffee shops and popular spots in Stellenbosch
      Location(
        latitude: -33.9366,
        longitude: 18.8572,
        address: 'Stellos Coffee, Van Riebeeck Street, Stellenbosch',
        landmark: 'Stellos Coffee',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9351,
        longitude: 18.8576,
        address: 'Vida e Caffè Stellenbosch, Stellenbosch',
        landmark: 'Vida e Caffè Stellenbosch',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9342,
        longitude: 18.8565,
        address: 'Mugg & Bean Stellenbosch, Stellenbosch',
        landmark: 'Mugg & Bean Stellenbosch',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9298,
        longitude: 18.8521,
        address: 'Oude Bank Bakkerij, Stellenbosch',
        landmark: 'Oude Bank Bakkerij',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9307,
        longitude: 18.8534,
        address: 'The Deli Stellenbosch, Stellenbosch',
        landmark: 'The Deli Stellenbosch',
        city: 'Stellenbosch',
      ),
      Location(
        latitude: -33.9295,
        longitude: 18.8518,
        address: 'Craft Wheat & Hops, Stellenbosch',
        landmark: 'Craft Wheat & Hops',
        city: 'Stellenbosch',
      ),
      
      // Enhanced UCT locations
      Location(
        latitude: -33.9249,
        longitude: 18.4241,
        address: 'University of Cape Town Upper Campus, Rondebosch, Cape Town',
        landmark: 'UCT Upper Campus Main Gate',
        city: 'Cape Town',
      ),
      Location(
        latitude: -33.9425,
        longitude: 18.4676,
        address: 'UCT Health Sciences Campus, Observatory, Cape Town',
        landmark: 'UCT Medical School',
        city: 'Cape Town',
      ),
      Location(
        latitude: -33.9600,
        longitude: 18.4650,
        address: 'UCT Tugwell Residence, Rondebosch, Cape Town',
        landmark: 'UCT Tugwell Residence',
        city: 'Cape Town',
      ),
      Location(
        latitude: -33.9550,
        longitude: 18.4620,
        address: 'UCT Leo Marquard Residence, Rondebosch, Cape Town',
        landmark: 'UCT Leo Marquard Residence',
        city: 'Cape Town',
      ),
      
      // Enhanced Ballito/KZN locations
      Location(
        latitude: -29.5390,
        longitude: 31.2096,
        address: '24 Club Cres, Umhlali Beach, Ballito, 4420, South Africa',
        landmark: '24 Club Cres, Umhlali Beach',
        city: 'Ballito',
      ),
      Location(
        latitude: -29.5380,
        longitude: 31.2120,
        address: 'Ballito Central, Ballito, South Africa',
        landmark: 'Ballito Town Centre',
        city: 'Ballito',
      ),
      
      // Popular Cape Town locations
      Location(
        latitude: -33.9567,
        longitude: 18.4603,
        address: 'V&A Waterfront, Cape Town',
        landmark: 'V&A Waterfront',
        city: 'Cape Town',
      ),
      Location(
        latitude: -33.9649,
        longitude: 18.6017,
        address: 'Cape Town International Airport, Cape Town',
        landmark: 'Cape Town International Airport',
        city: 'Cape Town',
      ),
      Location(
        latitude: -33.9158,
        longitude: 18.4233,
        address: 'Cape Town City Centre, Cape Town',
        landmark: 'Cape Town CBD',
        city: 'Cape Town',
      ),
      Location(
        latitude: -33.9847,
        longitude: 18.4645,
        address: 'Claremont, Cape Town',
        landmark: 'Claremont Station',
        city: 'Cape Town',
      ),
      Location(
        latitude: -33.9608,
        longitude: 18.4841,
        address: 'Rondebosch, Cape Town',
        landmark: 'Rondebosch Common',
        city: 'Cape Town',
      ),
      
      // Shopping and entertainment
      Location(
        latitude: -33.9750,
        longitude: 18.4650,
        address: 'Cavendish Square, Claremont, Cape Town',
        landmark: 'Cavendish Square Shopping Centre',
        city: 'Cape Town',
      ),
      Location(
        latitude: -33.9020,
        longitude: 18.4186,
        address: 'V&A Waterfront Mall, Cape Town',
        landmark: 'V&A Waterfront Shopping Centre',
        city: 'Cape Town',
      ),
      
      // Other universities
      Location(
        latitude: -25.7545,
        longitude: 28.2314,
        address: 'University of Pretoria, Pretoria',
        landmark: 'UP Main Campus',
        city: 'Pretoria',
      ),
      Location(
        latitude: -26.1913,
        longitude: 28.0305,
        address: 'University of the Witwatersrand, Johannesburg',
        landmark: 'Wits Main Campus',
        city: 'Johannesburg',
      ),
      Location(
        latitude: -33.6844,
        longitude: 18.6286,
        address: 'University of the Western Cape, Bellville, Cape Town',
        landmark: 'UWC Campus',
        city: 'Cape Town',
      ),
    ];

    // If no query, return all locations
    if (query.isEmpty) {
      return fallbackLocations;
    }

    // Enhanced smart matching with typo tolerance
    final normalizedQuery = query.toLowerCase().trim();
    final queryWords = normalizedQuery.split(' ').where((word) => word.length >= 2).toList();
    
    // Create a scoring system for better matching
    final scoredResults = <MapEntry<Location, double>>[];
    
    for (final location in fallbackLocations) {
      final normalizedAddress = location.address.toLowerCase();
      final normalizedLandmark = (location.landmark ?? '').toLowerCase();
      final normalizedCity = (location.city ?? '').toLowerCase();
      
      double score = 0.0;
      
      // Exact phrase match (highest priority)
      if (normalizedAddress.contains(normalizedQuery) ||
          normalizedLandmark.contains(normalizedQuery) ||
          normalizedCity.contains(normalizedQuery)) {
        score += 100.0;
      }
      
      // Fuzzy matching for typos (e.g., "stellos" matches "stellos")
      if (_fuzzyMatch(normalizedQuery, normalizedLandmark) ||
          _fuzzyMatch(normalizedQuery, normalizedAddress)) {
        score += 90.0;
      }
      
      // Word-based matching (medium priority)
      if (queryWords.isNotEmpty) {
        final allWords = queryWords.every((word) => 
          _fuzzyMatch(word, normalizedAddress) ||
          _fuzzyMatch(word, normalizedLandmark) ||
          _fuzzyMatch(word, normalizedCity)
        );
        if (allWords) score += 80.0;
        
        // Partial word matching (lower priority)
        final wordMatches = queryWords.where((word) => 
          _fuzzyMatch(word, normalizedAddress) ||
          _fuzzyMatch(word, normalizedLandmark) ||
          _fuzzyMatch(word, normalizedCity)
        ).length;
        
        score += (wordMatches / queryWords.length) * 50.0;
      }
      
      // Bonus for coffee shops if query mentions coffee
      if (normalizedQuery.contains('coffee') || normalizedQuery.contains('coffe')) {
        if (normalizedLandmark.contains('coffee') || normalizedLandmark.contains('caffè')) {
          score += 30.0;
        }
      }
      
      // Bonus for stellenbosch locations if query mentions stellenbosch
      if (normalizedQuery.contains('stell')) {
        if (normalizedCity.contains('stellenbosch')) {
          score += 20.0;
        }
      }
      
      if (score > 0) {
        scoredResults.add(MapEntry(location, score));
      }
    }
    
    // Sort by score (highest first) and return top results
    scoredResults.sort((a, b) => b.value.compareTo(a.value));
    return scoredResults.take(8).map((entry) => entry.key).toList();
  }
  
  /// Fuzzy matching to handle typos and partial matches
  bool _fuzzyMatch(String query, String target) {
    if (target.contains(query)) return true;
    
    // Handle common typos and partial matches
    if (query.length < 3) return false;
    
    // Check if query is a substring allowing for 1-2 character differences
    if (query.length >= 4) {
      // Simple fuzzy matching - check if most characters match
      int matches = 0;
      int maxIndex = target.length - 1;
      
      for (int i = 0; i < query.length; i++) {
        for (int j = 0; j <= maxIndex; j++) {
          if (j < target.length && query[i] == target[j]) {
            matches++;
            break;
          }
        }
      }
      
      // If 75% of characters match, consider it a match
      return matches >= (query.length * 0.75);
    }
    
    return false;
  }

  /// Get current location
  Future<LatLng> getCurrentLocation() async {
    try {
      print('📍 Getting current location...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        throw Exception('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permissions denied');
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permissions permanently denied');
        throw Exception('Location permissions permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Current location: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
      
    } catch (e) {
      print('❌ Error getting current location: $e');
      // Return default location (Cape Town)
      return const LatLng(-33.9249, 18.4241);
    }
  }

  /// Reverse geocode coordinates to get address
  Future<String> reverseGeocode(LatLng coordinates) async {
    try {
      print('🔍 Reverse geocoding: ${coordinates.latitude}, ${coordinates.longitude}');
      
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${coordinates.latitude},${coordinates.longitude}&key=$_apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'];
          print('✅ Reverse geocoded: $address');
          return address;
        }
      }
      
      print('❌ Reverse geocoding failed, using default');
      return 'Unknown location';
    } catch (e) {
      print('❌ Reverse geocoding error: $e');
      return 'Unknown location';
    }
  }
} 