// services/user_videos_service.dart
import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/model/reel_model.dart';

class UserVideosService {
  final ApiController _api = ApiController();

  Future<List<ReelModel>> getUserVideos(String userId) async {
    try {
      final res = await _api.get('/media/my-videos/$userId');

      if (res['success'] == true) {
        final List data = res['videos'] ?? [];
        return data.map((e) => _mapToReelModel(e)).toList();
      }
      return [];
    } catch (e) {
      print('getUserVideos error: $e');
      return [];
    }
  }

  Future<List<ReelModel>> getLikedReels(String userId, int page, int limit) async {
    try {
      final res = await _api.get(
        '/reels/liked/$userId?page=$page&limit=$limit',
      );

      if (res['success'] == true) {
        final List data = res['likedReels'] ?? [];
        return data.map((e) => _mapToReelModel(e)).toList();
      }
      return [];
    } catch (e) {
      print('getLikedReels error: $e');
      return [];
    }
  }

  Future<List<ReelModel>> getSavedReels(String userId, int page, int limit) async {
    try {
      final res = await _api.get(
        '/reels/saved/$userId?page=$page&limit=$limit',
      );

      if (res['success'] == true) {
        final List data = res['savedReels'] ?? [];
        return data.map((e) => _mapToReelModel(e)).toList();
      }
      return [];
    } catch (e) {
      print('getSavedReels error: $e');
      return [];
    }
  }

  ReelModel _mapToReelModel(Map<String, dynamic> e) {
    return ReelModel(
      id: e['id'],
      videoUrl: e['url'],
      thumbnail: e['thumbnail'],
      description: e['description'] ?? '',
      hashtags: List<String>.from(e['hashtags'] ?? []),
      likeCount: e['likeCount'] ?? 0,
      commentCount: e['commentCount'] ?? 0,
      saveCount: e['saveCount'] ?? 0,
      shareCount: e['shareCount'] ?? 0,
      isVerified: false,
      musicTitle: 'Original Sound',
      username: e['username'] ?? '',
    );
  }
}