import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class LocationSearchDelegate extends SearchDelegate<String> {
  final String sessionToken;

  LocationSearchDelegate() : sessionToken = DateTime.now().toIso8601String();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container();
    }

    return FutureBuilder<List<dynamic>>(
      future: getPlacePredictions(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final predictions = snapshot.data ?? [];

        return ListView.builder(
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final prediction = predictions[index];
            final description = prediction['description'] as String;
            final structuredFormatting =
                prediction['structured_formatting'] ?? {};
            final mainText = structuredFormatting['main_text'] ?? description;
            final secondaryText = structuredFormatting['secondary_text'] ?? '';

            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(
                mainText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: secondaryText.isNotEmpty ? Text(secondaryText) : null,
              onTap: () {
                close(context, description);
              },
            );
          },
        );
      },
    );
  }

  static Future<List<dynamic>> getPlacePredictions(String input) async {
    if (input.isEmpty) return [];

    final String apiKey = ApiConfig.googleMapsApiKey;
    final String sessionToken = DateTime.now()
        .toIso8601String(); // New token for each request if not managed statefully
    // sessiontoken is important for billing (groups query chars into one session)
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&sessiontoken=$sessionToken';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'];
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          debugPrint('Failed to load suggestions: ${data['status']}');
          return [];
        }
      } else {
        throw Exception('Failed to connect to Google Maps API');
      }
    } catch (e) {
      debugPrint('Error fetching places: $e');
      return [];
    }
  }
}
