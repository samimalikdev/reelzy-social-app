import 'package:get/get_rx/src/rx_types/rx_types.dart';

class Comment {
  final String id;
  final String userId;
  final String username;
  final String content;
  final String profilePic;
  final DateTime timeAgo;
  final RxInt likes;
  final RxBool isLiked;
  final bool isVerified;

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.profilePic,
    required this.timeAgo,
    int likesCount = 0,
    bool liked = false,
    this.isVerified = false,
  }) : likes = likesCount.obs,
       isLiked = liked.obs;

  factory Comment.fromJson(Map<String, dynamic> json) {
  final likesList = json['likes'] as List<dynamic>?;

  return Comment(
    id: json['_id'] ?? json['commentId'] ?? '',
    userId: json['userId'] ?? '',
    username: json['username'] ?? '',
    content: json['content'] ?? '',
    profilePic: json['profilePic'] ?? '',
    timeAgo: DateTime.tryParse(json['timeAgo'] ?? '') ?? DateTime.now(),
    likesCount: likesList?.length ?? 0,
    liked: json['isLiked'] ?? false,
    isVerified: json['isVerified'] ?? false,
  );
}



  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timeAgo);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}