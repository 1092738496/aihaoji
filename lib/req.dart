import 'dart:convert';

import 'package:http/http.dart' as http;

class Req {
  static Future<dynamic> fetchData(url, cookie, authorization) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Cookie": cookie,
        "Authorization": authorization,
        "Content-Type": "application/json",
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
      },
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load data');
    }
  }

   static Future<dynamic> PostfetchData(url, cookie, authorization, Map<String, dynamic>? bodyData) async {

    //print(jsonEncode(bodyData));
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Cookie": cookie,
        "Authorization": authorization,
        "Content-Type": "application/json",
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
      },
      body: bodyData != null ? jsonEncode(bodyData) : null,
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load data');
    }
  }
}
