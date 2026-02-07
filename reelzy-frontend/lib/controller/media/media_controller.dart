import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/model/reel_model.dart';

class MediaController extends GetxController {
  final ApiController _apiController = Get.find<ApiController>();
  
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxString error = ''.obs;
  
  final RxList<ReelModel> reels = <ReelModel>[].obs;
  
  final RxList<String> userReelsUrls = <String>[].obs;
  final RxList<String> userImageUrls = <String>[].obs;
  
  final RxList<String> likedReelsUrls = <String>[].obs;
  final RxInt likedPage = 1.obs;
  final RxBool hasMoreLiked = true.obs;
  
  int currentPage = 1;
  final int pageSize = 10;
  
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    fetchMedia();
    if (_userId.isNotEmpty) {
      fetchMediaById(_userId);
    }
  }

  
  Future<void> fetchMedia({bool refresh = false}) async {
  try {
    if (refresh) {
      currentPage = 1;
      hasMoreData.value = true;
      reels.clear();
    }
    
    isLoading.value = true;
    error.value = '';

    final response = await _apiController.get(
      '/getMedia?page=$currentPage&limit=$pageSize&type=video&userId=$_userId'
    );

    if (response['success'] == true) {
      final List<dynamic> dataList = response['data'] ?? [];
      
      final newReels = dataList
          .map((json) => ReelModel.fromJson(json))
          .where((reel) => reel.videoUrl != null && reel.videoUrl!.isNotEmpty)
          .toList();

      if (refresh) {
        reels.assignAll(newReels);
      } else {
        reels.addAll(newReels);
      }

      hasMoreData.value = newReels.length >= pageSize;
      
      print('Loaded ${newReels.length} reels, page $currentPage');
    } else {
      error.value = 'Failed to load media';
    }
  } catch (e) {
    error.value = 'Error fetching media: $e';
    print('$error');
    
    Get.snackbar(
      'Error',
      'Failed to load reels',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  } finally {
    isLoading.value = false;
  }
}

  Future<void> loadMoreMedia() async {
    if (isLoadingMore.value || !hasMoreData.value) {
      print('Already loading or no more data');
      return;
    }

    try {
      isLoadingMore.value = true;
      currentPage++;
      
      print('Loading page $currentPage...');
      
      await fetchMedia();
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshMedia() async {
    print('Refreshing media...');
    await fetchMedia(refresh: true);
  }

  
  Future<void> fetchMediaById(String userId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiController.get('/getMediaById?userId=$userId');

      if (response != null && response['success'] == true) {
        final List<dynamic> dataList = response['data'] ?? [];
        
        final videos = <String>[];
        final images = <String>[];
        
        for (var item in dataList) {
          final type = item['type']?.toString().toLowerCase() ?? '';
          final url = item['url']?.toString() ?? '';
          
          if (url.isNotEmpty) {
            if (type == 'video') {
              videos.add(url);
            } else if (type == 'image') {
              images.add(url);
            }
          }
        }
        
        userReelsUrls.value = videos;
        userImageUrls.value = images;
        
        print('Found ${videos.length} videos and ${images.length} images for user $userId');
      }
    } catch (e) {
      error.value = 'Error fetching media by ID: $e';
      print('$error');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLikedReels({bool refresh = false}) async {
    try {
      if (refresh) {
        likedPage.value = 1;
        hasMoreLiked.value = true;
        likedReelsUrls.clear();
      }
      
      isLoading.value = true;

      final response = await _apiController.get(
        '/media/liked?userId=$_userId&page=${likedPage.value}&limit=$pageSize'
      );

      if (response['success'] == true) {
        final List<dynamic> dataList = response['data'] ?? [];
        
        final urls = dataList
            .map((item) => item['url']?.toString() ?? '')
            .where((url) => url.isNotEmpty)
            .toList();

        if (refresh) {
          likedReelsUrls.assignAll(urls);
        } else {
          likedReelsUrls.addAll(urls);
        }

        hasMoreLiked.value = urls.length >= pageSize;
        
        print('Loaded ${urls.length} liked reels, page ${likedPage.value}');
      }
    } catch (e) {
      print('Error fetching liked reels: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreLikedReels() async {
    if (isLoadingMore.value || !hasMoreLiked.value) return;

    try {
      isLoadingMore.value = true;
      likedPage.value++;
      await fetchLikedReels();
    } finally {
      isLoadingMore.value = false;
    }
  }

  
  Future<void> toggleLike(ReelModel reel) async {
    if (_userId.isEmpty) {
      Get.snackbar('Error', 'Please login to like reels');
      return;
    }

    final wasLiked = reel.isLiked;
    reel.isLiked = !reel.isLiked;
    reel.likeCount += reel.isLiked ? 1 : -1;
    reels.refresh();

    try {
      final res = await _apiController.post(
        '/media/${reel.id}/like',
        {'userId': _userId},
      );

      if (res['success'] == true) {
        reel.isLiked = res['liked'] ?? reel.isLiked;
        reel.likeCount = res['likesCount'] ?? reel.likeCount;
        reels.refresh();
      }
    } catch (e) {
      reel.isLiked = wasLiked;
      reel.likeCount += wasLiked ? 1 : -1;
      reels.refresh();
      print('Error toggling like: $e');
      
   
    }
  }

  Future<void> toggleSave(ReelModel reel) async {
    if (_userId.isEmpty) {
      Get.snackbar('Error', 'Please login to save reels');
      return;
    }

    final wasSaved = reel.isSaved;
    reel.isSaved = !reel.isSaved;
    reel.saveCount += reel.isSaved ? 1 : -1;
    reels.refresh();

    try {
      final res = await _apiController.post(
        '/media/${reel.id}/save',
        {'userId': _userId},
      );

      if (res['success'] == true) {
        reel.isSaved = res['saved'] ?? reel.isSaved;
        reel.saveCount = res['savesCount'] ?? reel.saveCount;
        reels.refresh();
      }
    } catch (e) {
      reel.isSaved = wasSaved;
      reel.saveCount += wasSaved ? 1 : -1;
      reels.refresh();
      print('Error save: $e');
      
      Get.snackbar(
        'Error',
        'Failed to update save',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> shareReel(ReelModel reel) async {
    reel.shareCount += 1;
    reels.refresh();

    try {
      final res = await _apiController.post(
        '/media/${reel.id}/share',
        {'userId': _userId},
      );

      if (res['success'] == true) {
        reel.shareCount = res['shareCount'] ?? reel.shareCount;
        reels.refresh();
      }
      
      Get.snackbar(
        'Share',
        'Sharing ${reel.username}\'s reel',
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.share, color: Colors.white),
      );
    } catch (e) {
      reel.shareCount -= 1;
      reels.refresh();
      print('Error sharing reel: $e');
    }
  }


  ReelModel? getReelById(String id) {
    try {
      return reels.firstWhere((reel) => reel.id == id);
    } catch (e) {
      return null;
    }
  }

  bool isReelLiked(String reelId) {
    final reel = getReelById(reelId);
    return reel?.isLiked ?? false;
  }

  bool isReelSaved(String reelId) {
    final reel = getReelById(reelId);
    return reel?.isSaved ?? false;
  }

  void clearData() {
    reels.clear();
    userReelsUrls.clear();
    userImageUrls.clear();
    likedReelsUrls.clear();
    error.value = '';
    currentPage = 1;
    likedPage.value = 1;
    hasMoreData.value = true;
    hasMoreLiked.value = true;
  }

  Future<void> refreshUserMedia(String userId) async {
    try {
      isLoading.value = true;
      await fetchMediaById(userId);
    } catch (e) {
      error.value = 'Error refreshing media: $e';
      print('$error');
    } finally {
      isLoading.value = false;
    }
  }
}