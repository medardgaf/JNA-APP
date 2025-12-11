import '../utils/api.dart';

class DiagnosticService {
  static Future<void> checkRawResponse() async {
    print("========================================");
    print("DÉBUT DU DIAGNOSTIC DE LA RÉPONSE SERVEUR");
    print("========================================");

    try {
      // On force Dio à renvoyer une String brute
      final response = await Api.dio.get<String>("/dashboard?action=stats");

      final rawData = response.data;

      print("Code de statut HTTP : ${response.statusCode}");
      print("Type de la réponse reçue : ${rawData.runtimeType}");

      if (rawData == null) {
        print("ERREUR : La réponse du serveur est NULL.");
        return;
      }

      print("\n--- DÉBUT DE LA RÉPONSE BRUTE ---");
      print(rawData);
      print("--- FIN DE LA RÉPONSE BRUTE ---\n");

      print("Analyse des caractères autour de la position 283...");
      final length = rawData.length;
      final start = (283 - 10).clamp(0, length);
      final end = (283 + 10).clamp(0, length);

      print("Extrait de la réponse :");
      print("...${rawData.substring(start, end)}...");

      print("\nCaractère à la position 283 (index 282) : '${rawData[282]}'");
      print("Code Unicode du caractère : ${rawData.codeUnitAt(282)}");
    } catch (e) {
      print("ERREUR LORS DE L'APPEL DIAGNOSTIC : $e");
    }

    print("========================================");
    print("FIN DU DIAGNOSTIC");
    print("========================================");
  }
}
