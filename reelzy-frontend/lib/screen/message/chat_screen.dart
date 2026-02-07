import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/screen/message/message_screen.dart';
import 'package:shorts_app/service/authentication.dart';

class ChatListController extends GetxController {
  final ApiController api = ApiController();

  var isLoading = false.obs;

  var chats = <ChatItem>[].obs;
  var filteredChats = <ChatItem>[].obs;

  var searchQuery = ''.obs;

  final String userId;

  ChatListController(this.userId);

  @override
  void onInit() {
    super.onInit();
    fetchChats();

    ever(searchQuery, (_) => applySearch());
  }

  Future<void> fetchChats() async {
    try {
      isLoading.value = true;

      final res = await api.get('/chats/$userId');

      if (res['success'] == true) {
        final list = (res['chats'] as List)
            .map((e) => ChatItem.fromJson(e))
            .toList();

        chats.assignAll(list);
        filteredChats.assignAll(list);
      }
    } catch (e) {
      print('Chat fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applySearch() {
    final q = searchQuery.value.trim().toLowerCase();

    if (q.isEmpty) {
      filteredChats.assignAll(chats); 
    } else {
      filteredChats.assignAll(
        chats.where((chat) {
          return chat.name.toLowerCase().contains(q) ||
              chat.lastMessage.toLowerCase().contains(q);
        }),
      );
    }
  }
}

class ChatListScreen extends StatelessWidget {
  final ChatListController controller = Get.put(
    ChatListController(Get.find<AuthenticationService>().userId!),
  );
  ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D7A4F), Color(0xFF3B9A65)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D7A4F).withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Row(
                      children: [

                        IconButton(onPressed: (){
                          Get.back();

                        }, icon: Icon(Icons.arrow_back_ios, color: Colors.white,)),

                        const SizedBox(width: 10,),
                        Text(
                          'Messages',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                    
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          controller.searchQuery.value = value;
                        },
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search messages...',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF9FA5AA),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF2D7A4F),
                            size: 22,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.filteredChats.isEmpty) {
                  return const Center(child: Text('No chats found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: controller.filteredChats.length,
                  itemBuilder: (_, index) {
                    return _ChatListTile(chat: controller.filteredChats[index]);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}


class _ChatListTile extends StatelessWidget {
  final ChatItem chat;

  const _ChatListTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Get.to(
              MessageScreen(
                user: UserProfile(
                  userId: chat.userId,
                  username: chat.name,
                  profilePic: chat.avatar, bio: '', followersCount: 0, followingCount: 0,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2D7A4F).withOpacity(0.3),
                            const Color(0xFF3B9A65).withOpacity(0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D7A4F).withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(chat.avatar),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.name,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1A1A1A),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            chat.time,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9FA5AA),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage,
                              style: GoogleFonts.inter(
                                color:
                                    chat.unreadCount > 0
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFF6B7280),
                                fontSize: 14,
                                fontWeight:
                                    chat.unreadCount > 0
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2D7A4F),
                                    Color(0xFF3B9A65),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatItem {
  final String userId; 
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unreadCount;

  ChatItem({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
  });

  factory ChatItem.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};

    return ChatItem(
      userId: user['userId'] ?? '', 
      name: user['username'] ?? 'Unknown',
      avatar:
          (user['profilePic'] != null && user['profilePic'] != '')
              ? user['profilePic']
              : 'https://i.pravatar.cc/150?img=1',
      lastMessage: json['lastMessage'] ?? '',
      time:
          json['lastMessageTime'] != null
              ? _formatTime(json['lastMessageTime'])
              : '',
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  static String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}
