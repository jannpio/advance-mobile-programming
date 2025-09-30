import 'dart:convert';
import 'package:http/http.dart';
import 'package:pioquinto_advmobprog/constants.dart';

class ArticleService {
  List listData = [];

  Future<List> getAllArticle() async {
    try {
      final response = await get(
        Uri.parse('$host/api/articles'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Dart/3.0 (Flutter)'
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        listData = decodedData['articles'];

        print('List data: $listData');
        return listData;
      } else {
        print('Response: ${response.body}');
        throw Exception('Failed to load data');
      }
    } catch (error) {
      print('Error: $error');
      throw error;
    }
  }


  Future<Map> createArticle(dynamic article) async {
    try {
      final response = await post(
        Uri.parse('$host/api/articles'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(article),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map mapData =jsonDecode(response.body);
        return mapData;
      } else {
        throw Exception('Failed to create article: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      print('Error: $error');
      throw error;
    }
  }

  Future<Map> updateArticle(String id, dynamic article) async {
    try {
      final response = await put(
        Uri.parse('$host/api/articles/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(article),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map mapData =jsonDecode(response.body);
        return mapData;
      } else {
        throw Exception('Failed to update article: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      print('Error: $error');
      throw error;
    }
  }
}