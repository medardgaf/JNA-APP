// lib/services/NotificationService.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// Ce gestionnaire global est nécessaire pour les notifications en avant-plan
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // URL de votre contrôleur de notification unifié
  static const String _notificationApiUrl =
      "https://k.jnatg.org/api/controllers/NotificationController.php";

  /// Initialise tout le service de notification.
  Future<void> initialize() async {
    // Demander la permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print("Permission de notification refusée.");
    }

    // Initialiser les notifications locales pour l'avant-plan
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Gérer les messages reçus quand l'app est en avant-plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Gérer les messages quand l'app est en arrière-plan et qu'on clique sur la notif
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Gérer le cas où l'app est fermée et ouverte par une notification
    FirebaseMessaging.instance
        .getInitialMessage()
        .then(_handleMessageOpenedApp);
  }

  /// Récupère le token de l'appareil et l'envoie au backend pour l'enregistrer.
  Future<void> getAndRegisterToken(int membreId) async {
    final String? token = await _firebaseMessaging.getToken();
    if (token == null) {
      print("Impossible d'obtenir le token FCM.");
      return;
    }
    print("FCM Token: $token");

    try {
      final response = await http.post(
        Uri.parse(_notificationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'register_token',
          'membre_id': membreId,
          'fcm_token': token,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print("Token FCM enregistré avec succès pour le membre $membreId.");
        } else {
          print(
              "Erreur lors de l'enregistrement du token: ${responseData['message']}");
        }
      } else {
        print(
            "Erreur serveur lors de l'enregistrement du token: ${response.statusCode}");
      }
    } catch (e) {
      print("Exception lors de l'enregistrement du token: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Message reçu en avant-plan: ${message.notification?.title}');
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            channelDescription: 'your_channel_description',
            icon: android.smallIcon,
            // other properties...
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage? message) {
    if (message != null) {
      print('Notification cliquée: ${message.messageId}');
      _handleNotificationData(message.data);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      final data = jsonDecode(payload);
      _handleNotificationData(data);
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    // Utilisez navigatorKey pour naviguer depuis n'importe où dans l'app
    // Exemple : if (data['type'] == 'cotisation') { navigatorKey.currentState?.pushNamed('/cotisations'); }
    print("Données de la notification: $data");
  }
}
