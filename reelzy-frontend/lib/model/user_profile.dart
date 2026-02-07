class UserProfile {
  final String userId;
  final String username;
  final String profilePic;
  final String bio;
  final int followersCount;
  final int followingCount;
  final bool? isFollowing;
  final DateTime? createdAt;

  UserProfile({
    required this.userId,
    required this.username,
    required this.profilePic,
    required this.bio,
    required this.followersCount,
    required this.followingCount,
     this.isFollowing,
     this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      profilePic: json['profilePic'] ?? '',
      bio: json['bio'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      isFollowing: json['isFollowing'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  UserProfile copyWith({
    bool? isFollowing,
    int? followersCount,
    int? followingCount,
  }) {
    return UserProfile(
      userId: this.userId,
      username: this.username,
      profilePic: this.profilePic,
      bio: this.bio,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      createdAt: this.createdAt,
    );
  }
}