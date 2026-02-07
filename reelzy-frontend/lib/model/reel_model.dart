class ReelModel {
  final String id;
  final String username;
  final String description;
  final List<String> hashtags;
  final String? videoUrl;
  final String? thumbnail;
  final String? profilePic;
  final String? targetId;

  int likeCount;
  int commentCount;
  int saveCount;
  int shareCount;

  final bool isVerified;
  final String musicTitle;

  bool isLiked;
  bool isSaved;

  ReelModel({
    required this.id,
    required this.username,
    required this.description,
    required this.hashtags,
    this.videoUrl,
    this.thumbnail,
    required this.likeCount,
    required this.commentCount,
    required this.saveCount,
    required this.shareCount,
    required this.isVerified,
    required this.musicTitle,
    this.isLiked = false,
    this.isSaved = false,
    this.profilePic,
    this.targetId,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '@user',
      description: json['caption'] ?? json['description'] ?? '', 
      hashtags: List<String>.from(json['hashtags'] ?? []),
      videoUrl: json['url'] ?? json['videoUrl'], 
      thumbnail: json['thumbnail'],
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      saveCount: json['saveCount'] ?? 0,
      shareCount: json['shareCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      musicTitle: json['musicTitle'] ?? 'Original Sound',
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      profilePic: json['profilePic'],
      targetId: json['targetId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'description': description,
      'hashtags': hashtags,
      'videoUrl': videoUrl,
      'thumbnail': thumbnail,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'saveCount': saveCount,
      'shareCount': shareCount,
      'isVerified': isVerified,
      'musicTitle': musicTitle,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'profilePic': profilePic,
      'targetId': targetId,
    };
  }
}
