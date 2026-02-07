import 'dart:async';

import 'package:get/get.dart';
import 'package:get/get_connect/connect.dart';
import 'package:get/get_core/src/get_main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiController {
  final String baseUrl = 'YOUR URL';

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('REQUEST: GET $url');

    try {
      final response = await http.get(url);

      print('RESPONSE: ${response.statusCode} $url');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        //   print(response.body);
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      print('GET Error: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    print('REQUEST: POST $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      print('RESPONSE: ${response.statusCode} $url');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      print('POST Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> postT(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      print('REQUEST: POST $baseUrl$endpoint');
      print('DATA: $data');

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              print('API timeout after 15 seconds');
              throw TimeoutException('Request timeout');
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } on TimeoutException catch (e) {
      print('Timeout: $e');
      return null;
    } catch (e) {
      print('API Error: $e');
      return null;
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      print('PATCH Error: $e');
      rethrow;
    }
  }
}
