import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    if (kIsWeb) return;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Nova mensagem recebida: ${message.notification?.title}');
      }
    });
  }

  Future<String?> getToken() async {
    if (kIsWeb) return null;
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }
}
