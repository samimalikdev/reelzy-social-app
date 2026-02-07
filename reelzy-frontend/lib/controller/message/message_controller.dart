import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorts_app/model/message_model.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/service/chat_service.dart';

class MessageController extends GetxController
    with GetTickerProviderStateMixin {
  final UserProfile userProfile;

  MessageController({required this.userProfile});

  final ChatService chatService =
      Get.find<ChatService>();

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  var isTyping = false.obs;
  var messages = <Message>[].obs;
  var isOnline = true.obs;



  final userId = FirebaseAuth.instance.currentUser!.uid;
  var textFieldKey = UniqueKey().obs;

  @override
  void onInit() {
    super.onInit();

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
  
  chatService.socket.on('message', (data) {

    try {

      if (data['senderId'] == userId) {
        print('own message');
        return;
      }

      if (data['senderId'] == userProfile.userId && data['receiverId'] == userId) {
        final message = Message(
          id: data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: data['text'] ?? '',
          isMe: false,
          timestamp: DateTime.parse(data['timestamp']),
          isRead: data['isRead'] ?? false,
        );
        
        
        final exists = messages.any((m) => m.id == message.id);

        if (!exists) {
          messages.add(message);
          _scrollToBottom();
        } else {
          print('Duplicate message');
        }
      } else {
        print('Message does not belong to this conversation');
      }
    } catch (e) {
      print('rror message: $e');
    }
  });

  chatService.socket.on('typing', (data) {

    if (data['senderId'] == userProfile.userId) {
      isTyping.value = data['isTyping'] ?? false;
    }
  });
}

  @override
  void onClose() {
    chatService.socket.off('message');
    chatService.socket.off('typing');

    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void sendMessage(String receiverId, String text) {
  if (text.trim().isEmpty) return;



  final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  final tempMessage = Message(
    id: tempId,
    text: text,
    isMe: true,
    timestamp: DateTime.now(),
    isRead: false,
  );

  messages.add(tempMessage);

  chatService.socket.emitWithAck(
    'send_message',
    {
      'senderId': userId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': "",
    },
    ack: (response) {
      
      messages.removeWhere((m) => m.id == tempId);
      
      if (response != null && response is Map) {
        final realMessage = Message(
          id: response['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: response['text'] ?? text,
          isMe: true,
          timestamp: DateTime.parse(response['timestamp'] ?? DateTime.now().toIso8601String()),
          isRead: response['isRead'] ?? false,
        );
        
        if (!messages.any((m) => m.id == realMessage.id)) {
          messages.add(realMessage);
        } else {
          print('Message already exists with ID: ${realMessage.id}');
        }
      }
    },
  );

  textController.clear();
  textFieldKey.value = UniqueKey();

  _scrollToBottom();
}

  Future<void> loadOldMessages() async {
    try {
      final oldMsgs = await chatService.getOldConversations(
        userId,
        userProfile.userId,
        1,
        50,
      );

      messages.clear();

      for (var data in oldMsgs) {
        final msg = Message(
          id: data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          text: data['text'] ?? '',
          isMe: data['senderId'] == userId,
          timestamp: DateTime.parse(
            data['timestamp'], 
          ),
          isRead: data['isRead'] ?? false,
        );
        messages.add(msg);
      }

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      _scrollToBottom();
    } catch (e) {
      print('Error loading old messages: $e');
    }
  }

  void onTyping(bool typing) {
    chatService.isTyping(userId, userProfile.userId, typing);
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
