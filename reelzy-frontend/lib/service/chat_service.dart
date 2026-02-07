import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/controller/profile/my_profile_controller.dart';
import 'package:shorts_app/service/calling_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatService extends GetxService {
  static const String _socketUrl = 'PASTE URL HERE';

  IO.Socket? _socket; 

  IO.Socket get socket {
    if (_socket == null) {
      throw Exception('Call connect() first.');
    }
    return _socket!;
  }

  bool get isConnected => _socket?.connected ?? false;

  final ApiController apiController = ApiController();

  void connect(String userId) {
    if (_socket != null && _socket!.connected) {
      print('Socket already connected');
      return;
    }

    _socket = IO.io(_socketUrl, {
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.on('follow:update', (data) {
      final myProfileController = Get.find<MyProfileController>();
      if (data['followingCount'] != null) {
        myProfileController.followingCount.value = data['followingCount'];
      }
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('socket with UID: $userId');

      _socket!.emit('register', {'userId': userId});

      final callingService = Get.find<CallingService>();
      callingService.init(
        sharedSocket: _socket!,
        userId: userId,
      );
    });

    _socket!.on('message', (data) {
      print('New message: $data');
    });

    _socket!.on('typing', (data) {
      print('Typing: $data');
    });

    _socket!.onDisconnect((_) => print('Disconnected from socket'));
  }

  void sendMessage(String senderId, String receiverId, String text) {
    if (_socket == null || !_socket!.connected) {
      print('Socket not connected');
      return;
    }

    _socket!.emitWithAck(
      'send_message',
      {
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'imageUrl': "",
      },
      ack: (response) {
        print('Response: $response');
      },
    );
  }

  void isTyping(String senderId, receiverId, bool isTyping) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('typing', {
      'senderId': senderId,
      'receiverId': receiverId,
      'isTyping': isTyping,
    });
  }

  Future<List<dynamic>> getOldConversations(
    String user1,
    String user2,
    int page,
    int limit,
  ) async {
    final url =
        '/conversation?user1=$user1&user2=$user2&page=$page&limit=$limit';

    try {
      final response = await apiController.get(url);
      if (response != null && response['data'] != null) {
        return List<dynamic>.from(response['data']);
      } else {
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
