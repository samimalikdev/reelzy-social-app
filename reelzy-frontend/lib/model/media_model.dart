class MediaItem {
  final String id;
  final String url;
  final String type;
  final int size;
  final String originalname;
  final String uploadedAt;
  final String? caption;
  final String? thumbnail;
  final List<String>? hashtags;
  final String? username;
  final String? profilePic;
  final String? targetId;

  MediaItem({
    required this.id,
    required this.url,
    required this.type,
    required this.size,
    required this.originalname,
    required this.uploadedAt,
    this.caption,
    this.hashtags,
    this.thumbnail,    this.username,   this.profilePic,  this.targetId,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'], 
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
      originalname: json['originalname'] ?? '',
      uploadedAt: json['uploadedAt'] ?? '',
      caption: json['caption'],
      hashtags: List<String>.from(json['hashtags'] ?? []),
      thumbnail: json['thumbnail'],
      username: json['username'],
      profilePic: json['profilePic'],
      targetId: json['targetId'],

    );
  }

  bool get isVideo => type.toLowerCase() == 'video';
  bool get isImage => type.toLowerCase() == 'image';
}

class MediaResponse {
  final bool success;
  final int length;
  final List<MediaItem> data;

  MediaResponse({
    required this.success,
    required this.length,
    required this.data,
  });

  factory MediaResponse.fromJson(Map<String, dynamic> json) {
    return MediaResponse(
      success: json['success'] ?? false,
      length: json['length'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => MediaItem.fromJson(item))
          .toList() ?? [],
    );
  }

  List<String> get reelsUrls => data
      .where((item) => item.isVideo)
      .map((item) => item.url)
      .toList();

  List<String> get imageUrls => data
      .where((item) => item.isImage)
      .map((item) => item.url)
      .toList();
}
