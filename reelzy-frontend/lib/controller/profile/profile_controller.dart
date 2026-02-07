import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/controller/profile/follow_controller.dart';
import 'package:shorts_app/model/reel_model.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/screen/login/login_screen.dart';
import 'package:shorts_app/screen/message/message_screen.dart';
import 'package:shorts_app/service/authentication.dart';
import 'package:shorts_app/service/deep_link_service.dart';
import 'package:shorts_app/service/user_video_service.dart';

class ProfileController extends GetxController with GetTickerProviderStateMixin {
  ProfileController();

  final selectedTab = 0.obs;
  final isLoading = false.obs;

  late AnimationController pulseController;
  late AnimationController slideController;
  late AnimationController floatingController;

  final RxBool isFollowing = false.obs;
  final RxInt followersCount = 0.obs;
  final RxInt followingCount = 0.obs;
  final RxString username = ''.obs;
  final RxString currentUserId = ''.obs; 
  final RxString profilePic = ''.obs; 

  final ApiController _apiController = ApiController();
  
  FollowController get followController => Get.find<FollowController>();
  final RxList<ReelModel> userVideos = <ReelModel>[].obs;
  final RxList<ReelModel> userLikedVideos = <ReelModel>[].obs;
  final RxList<ReelModel> userSavedVideos = <ReelModel>[].obs;
  final UserVideosService _videosService = UserVideosService();

  final RxInt likedPage = 1.obs;
  final RxInt savedPage = 1.obs;
  final RxBool hasMoreLiked = true.obs;
  final RxBool hasMoreSaved = true.obs;
int get postsCount => userVideos.length;

  Future<void> loadUserVideos(String userId) async {
    final videos = await _videosService.getUserVideos(userId);
    userVideos.assignAll(videos);
  }

  Future<void> loadUserLikedReels(String userId, {bool loadMore = false}) async {
    if (!loadMore) {
      likedPage.value = 1;
      userLikedVideos.clear();
      hasMoreLiked.value = true;
    }

    if (!hasMoreLiked.value) return;

    final videos = await _videosService.getLikedReels(
      userId, 
      likedPage.value, 
      10
    );

    if (videos.isEmpty) {
      hasMoreLiked.value = false;
    } else {
      likedPage.value++;
      userLikedVideos.addAll(videos);
    }
  }

  Future<void> loadUserSavedReels(String userId, {bool loadMore = false}) async {
    if (!loadMore) {
      savedPage.value = 1;
      userSavedVideos.clear();
      hasMoreSaved.value = true;
    }

    if (!hasMoreSaved.value) return;

    final videos = await _videosService.getSavedReels(
      userId, 
      savedPage.value, 
      10
    );

    if (videos.isEmpty) {
      hasMoreSaved.value = false;
    } else {
      savedPage.value++;
      userSavedVideos.addAll(videos);
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    print('profileController INIT ${hashCode}');
  }

  void resetProfile() {
    selectedTab.value = 0;
    isLoading.value = true;
    isFollowing.value = false;
    followersCount.value = 0;
    followingCount.value = 0;
    username.value = '';
    currentUserId.value = '';
  }

  void _initializeAnimations() {
    pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
  }


  @override
  void changeTab(int index) {
    selectedTab.value = index;
    
    if (index == 1 && userLikedVideos.isEmpty) {
      loadUserLikedReels(currentUserId.value);
    } else if (index == 2 && userSavedVideos.isEmpty) {
      loadUserSavedReels(currentUserId.value);
    }
  }

    List<ReelModel> getVideosForCurrentTab() {
    switch (selectedTab.value) {
      case 0:
        return userVideos;
      case 1:
        return userLikedVideos;
      case 2:
        return userSavedVideos;
      default:
        return userVideos;
    }
  }

  void navigateToMessages(String userId, UserProfile user) {
    Get.to(() => MessageScreen(user: user));
  }

  void shareProfile() {
  final deepLinkService = Get.find<DeepLinkService>();
  
  deepLinkService.shareProfile(
    currentUserId.value,
    username.value,
  );
}

  void handleLogout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                Get.back();
                _performLogout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    AuthenticationService().logout();
    Get.offAll(() => LoginScreen());
    Get.snackbar(
      'Logged Out',
      'You have been successfully logged out',
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> toggleFollow(String targetUserId) async {
    await followController.toggleFollow(targetUserId);
    
    isFollowing.value = followController.followMap[targetUserId] ?? false;
    followersCount.value = followController.followersCountMap[targetUserId] ?? followersCount.value;
  }

    Future<void> getUserProfile(String userId) async {
    try {
      print('Fetching profile for userId: $userId');
      
      currentUserId.value = userId;
      isLoading.value = true;

      final currentUser = FirebaseAuth.instance.currentUser;
      final response = await _apiController.get(
        '/getUserProfile/$userId?currentUserId=${currentUser?.uid}'
      );

      if (response['success'] == true) {
        final data = response['data'];
        
        isFollowing.value = data['isFollowing'] ?? false;
        followersCount.value = data['followersCount'] ?? 0;
        followingCount.value = data['followingCount'] ?? 0;
        username.value = data['username'] ?? 'Unknown';
        profilePic.value = data['profilePic'] ?? '';
        
        followController.updateFollowStatus(
          userId,
          data['isFollowing'] ?? false,
          followersCount: data['followersCount'],
          followingCount: data['followingCount'],
        );
        
        await loadUserVideos(userId);
        
        print('Profile loaded for: ${username.value}');
      }
      
      isLoading.value = false;
    } catch (e) {
      print('getUserProfile error: $e');
      isLoading.value = false;
    }
  }


  Future<void> updateProfile(
  String? username,
  String? email,
  String? profilePic,
) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final body = {
      "username": username,
      "email": email,
      "profilePic": profilePic,
    }..removeWhere((key, value) => value == null);

    final response = await _apiController.patch('/update-profile/${user.uid}', body);

    if (response['success'] == true) {
      if (username != null) {
        await user.updateDisplayName(username);
      }
      if (profilePic != null) {
        await user.updatePhotoURL(profilePic);
      }
      
      await user.reload();

      await getUserProfile(user.uid);

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } 
  } catch (e) {
    print("updateProfile Error: $e");
    Get.snackbar(
      'Error',
      'Failed to update profile',
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

  @override
  void onClose() {
    pulseController.dispose();
    slideController.dispose();
    floatingController.dispose();
    print('profileController CLOSE ${hashCode}');
    super.onClose();
  }
}