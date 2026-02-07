// follow_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';

class FollowController extends GetxController {
  final RxMap<String, bool> followMap = <String, bool>{}.obs;
  
  final RxMap<String, int> followersCountMap = <String, int>{}.obs;
  final RxMap<String, int> followingCountMap = <String, int>{}.obs;

  final ApiController _apiController = ApiController();

  @override
  void onInit() {
    super.onInit();
    print('FollowController initialized');
  }

  Future<void> toggleFollow(String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final previousState = followMap[targetUserId] ?? false;
    final previousFollowersCount = followersCountMap[targetUserId] ?? 0;

    followMap[targetUserId] = !previousState;
    followersCountMap[targetUserId] = previousFollowersCount + (previousState ? -1 : 1);

    try {
      final response = await _apiController.post(
        '/toggleFollow/$targetUserId',
        {'userId': currentUser.uid},
      );

      if (response['success'] == true) {
        followMap[targetUserId] = response['isFollowing'];
        if (response['followersCount'] != null) {
          followersCountMap[targetUserId] = response['followersCount'];
        }
      } else {
        _revertFollowState(targetUserId, previousState, previousFollowersCount);
      }
    } catch (e) {
      _revertFollowState(targetUserId, previousState, previousFollowersCount);
      Get.snackbar(
        'Error',
        'Failed to update follow status',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _revertFollowState(String targetUserId, bool previousState, int previousCount) {
    followMap[targetUserId] = previousState;
    followersCountMap[targetUserId] = previousCount;
  }

  void updateFollowStatus(String userId, bool isFollowing, {int? followersCount, int? followingCount}) {
    followMap[userId] = isFollowing;
    if (followersCount != null) {
      followersCountMap[userId] = followersCount;
    }
    if (followingCount != null) {
      followingCountMap[userId] = followingCount;
    }
  }

  bool isFollowing(String userId) {
    return followMap[userId] ?? false;
  }

  int getFollowersCount(String userId) {
    return followersCountMap[userId] ?? 0;
  }

  int getFollowingCount(String userId) {
    return followingCountMap[userId] ?? 0;
  }

  @override
  void onClose() {
    print('FollowController closed');
    super.onClose();
  }
}