import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://k.jnatg.org/api/dashboard/member.php";

  static Future<Map<String, dynamic>> fetchDashboard({
    required int membreId,
    String role = "membre",
    int? year,
  }) async {
    final uri = Uri.parse(
        "$baseUrl?action=stats&role=$role&membre_id=$membreId${year != null ? "&year=$year" : ""}");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur API: ${response.statusCode}");
    }
  }
}
