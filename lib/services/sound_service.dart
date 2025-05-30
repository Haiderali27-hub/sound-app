import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SoundService {
  static const String _apiUrl = 'http://16.171.115.187:8000/auth/voice-detect';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sends the recorded audio file at [path] to your backend.
  /// Automatically includes the user's Access Token and FCM token.
  /// Expects a JSON response like { "label": "baby_crying", "confidence": 0.92 }.
  Future<Map<String, dynamic>> detectSound(String path) async {
    print('\n--- Sound Detection API Call Started ---');
    print('API URL: $_apiUrl');
    print('Audio file path: $path');

    // Get FCM token
    print('Getting FCM token...');
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      print('FCM token is null, cannot proceed');
      throw Exception('FCM token is null');
    }
    print('Got FCM token: ${fcmToken.substring(0, 10)}...');

    // Get fresh Access Token
    print('Getting fresh Access Token...');
    final accessToken = await _auth.currentUser?.getIdToken(true);
    if (accessToken == null) {
      print('Access Token is null, cannot proceed');
      throw Exception('Access Token is null');
    }
    print('Got Access Token: ${accessToken.substring(0, 10)}...');

    final uri = Uri.parse(_apiUrl);
    print('Creating multipart request...');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('audio', path))
      ..fields['token'] = accessToken  // Using Access Token instead of ID Token
      ..fields['fcm_token'] = fcmToken
      ..headers['Content-Type'] = 'multipart/form-data';

    print('Request created with:');
    print('- File: audio');
    print('- Access Token field: present');
    print('- FCM token field: present');
    print('- Content-Type: multipart/form-data');

    try {
      print('Sending request to server...');
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Request timed out after 30 seconds');
          throw TimeoutException('Request timed out');
        },
      );
      print('Request sent, waiting for response...');
      
      final response = await http.Response.fromStream(streamed);
      print('Response received:');
      print('- Status code: ${response.statusCode}');
      print('- Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          print('Successfully parsed response: $data');
          print('--- Sound Detection API Call Completed Successfully ---\n');
          return data;
        } catch (e) {
          print('Error parsing response JSON: $e');
          print('Raw response body: ${response.body}');
          throw Exception('Invalid JSON response from server');
        }
      } else {
        print('Server error: ${response.body}');
        print('--- Sound Detection API Call Failed ---\n');
        throw Exception('Sound API error: ${response.statusCode} - ${response.body}');
      }
    } on TimeoutException {
      print('Request timed out');
      print('--- Sound Detection API Call Failed with Timeout ---\n');
      rethrow;
    } catch (e) {
      print('Error in detectSound: $e');
      print('--- Sound Detection API Call Failed with Error ---\n');
      rethrow;
    }
  }
} 