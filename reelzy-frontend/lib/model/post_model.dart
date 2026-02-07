class Post {
  final String id;
  final String userId;
  final String content;

  final String? imageUrl;
  final String? linkTitle;
  final String? linkUrl;
  final String? linkImage;
  final String? location;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int likesCount;
  final int savesCount;
  final int commentsCount;
  final int shareCount;

  final bool isLiked;
  final bool isSaved;

  final String? username;
  final String? userAvatar;
  final String? userBio;
  final int followersCount;
  final int followingCount;

  Post({
    required this.id,
    required this.userId,
    required this.content,
     this.createdAt,
     this.updatedAt,

    this.imageUrl,
    this.linkTitle,
    this.linkUrl,
    this.linkImage,
    this.location,

    this.likesCount = 0,
    this.savesCount = 0,
    this.commentsCount = 0,
    this.shareCount = 0,

    this.isLiked = false,
    this.isSaved = false,

    this.username,
    this.userAvatar,
    this.userBio,
    this.followersCount = 0,
    this.followingCount = 0,
  });


  factory Post.fromJson(Map<String, dynamic> json) {
    int getCount(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is List) return value.length;
      return 0;
    }

    final user = json['user']; 

    return Post(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      content: json['content'] ?? json['postText'] ?? '',

      imageUrl: json['mediaUrl'] ?? json['imageUrl'] ?? json['postImage'],
      linkTitle: json['linkPreview']?['title'],
      linkUrl: json['linkPreview']?['url'],
      linkImage: json['linkImage'],
      location: json['location'],

      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),

      likesCount: json['likesCount'] ?? getCount(json['likes']),
      savesCount: json['savesCount'] ?? getCount(json['saves']),
      commentsCount: json['commentsCount'] ?? getCount(json['comments']),
      shareCount: json['shareCount'] ?? 0,

      isLiked: json['isLiked'] == true,
      isSaved: json['isSaved'] == true,

      username: user?['username'],
      userAvatar: user?['profilePic'],
      userBio: user?['bio'],
      followersCount: user?['followersCount'] ?? 0,
      followingCount: user?['followingCount'] ?? 0,
    );
  }


  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasLink => linkTitle != null && linkUrl != null;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }


  Post copyWith({
    bool? isLiked,
    bool? isSaved,
    int? likesCount,
    int? savesCount,
    int? commentsCount,
    int? shareCount,
    int? followersCount,
    int? followingCount,
  }) {
    return Post(
      id: id,
      userId: userId,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,

      imageUrl: imageUrl,
      linkTitle: linkTitle,
      linkUrl: linkUrl,
      linkImage: linkImage,
      location: location,

      likesCount: likesCount ?? this.likesCount,
      savesCount: savesCount ?? this.savesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      shareCount: shareCount ?? this.shareCount,

      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,

      username: username,
      userAvatar: userAvatar,
      userBio: userBio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}
