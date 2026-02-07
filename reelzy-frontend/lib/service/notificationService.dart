import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/screen/call/call_screen.dart';
import 'package:shorts_app/screen/message/message_screen.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin local =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('FCM token refreshed: $newToken');

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final apiController = Get.find<ApiController>();
        await apiController.post('/save-fcm-token', {
          'userId': userId,
          'fcmToken': newToken,
        });
      }
    });

    await local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (payload) {
        handlePayload(payload.payload);
      },
    );

    FirebaseMessaging.onMessage.listen(onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    final initialMsg = await _fcm.getInitialMessage();
    if (initialMsg != null) {
      handleMessage(initialMsg);
    }
  }

  static void onForegroundMessage(RemoteMessage message) {
    showLocal(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }

  static void handleMessage(RemoteMessage message) {
    handlePayload(message.data);
  }

  static void showLocal({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    const android = AndroidNotificationDetails(
      'main_channel',
      'Main Notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
    );

    local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: android),
      payload: jsonEncode(data),
    );
  }

  static void handlePayload(dynamic payload) {
    if (payload == null) return;

    final data = payload is String ? jsonDecode(payload) : payload;
    final type = data['type'];

    if (type == 'message') {
      final user = UserProfile(
        userId: data['senderId'],
        username: data['senderName'],
        profilePic: data['senderAvatar'],
        bio: '',
        followersCount: 0,
        followingCount: 0,
      );

      Get.to(() => MessageScreen(user: user));
    }

    if (type == 'call') {
      Get.to(
        () => CallScreen(
          receiverId: data['callerId'],
          receiverName: data['callerName'],
          receiverImg: data['callerAvatar'],
          isIncoming: true,
        ),
      );
    }
  }
}
