import 'dart:convert';

import 'package:frontend/core/configs/api_config.dart';
import 'package:frontend/core/configs/headers.dart';
import 'package:http/http.dart' as http;

class StatisticsService {
  static Future<dynamic> loadStatistics()async {
    final headers = await ApiHeaders.getAuthHeaders();
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.dashboardStats);
    final response= await http.get(url,headers: headers);

    if(response.statusCode==200){
      final data = json.decode(response.body);
      return data;
    }else {
      throw Exception('Failed to load statictis info');
    }

  }
}