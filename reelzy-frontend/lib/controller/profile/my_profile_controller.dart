import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/controller/profile/profile_controller.dart';
import 'package:http/http.dart' as http;
import 'package:shorts_app/model/reel_model.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/screen/login/login_screen.dart';
import 'package:shorts_app/screen/onboard/splash_screen.dart';
import 'package:shorts_app/service/authentication.dart';
import 'package:shorts_app/service/user_video_service.dart';

class MyProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final email = ''.obs;
  final profilePic = ''.obs;
  final bio = ''.obs;

  final RxBool isFollowing = false.obs;
  final RxInt followersCount = 0.obs;
  final RxInt followingCount = 0.obs;
  final RxString username = ''.obs;

  final selectedTab = 0.obs;

  final isLoading = false.obs;

  final RxList<ReelModel> myVideos = <ReelModel>[].obs;
  final likedVideos = <String>[].obs;

  final RxList<ReelModel> likedReelsUrls = <ReelModel>[].obs;
  final RxList<ReelModel> savedVideos = <ReelModel>[].obs;

  final RxInt likedPage = 1.obs;
  final RxBool hasMoreLiked = true.obs;

  late AnimationController pulseController;
  final ProfileController profileController = Get.find<ProfileController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final ApiController _api = ApiController();
  String userId = FirebaseAuth.instance.currentUser!.uid;
  late RxnString videoThumbnailPath;
  final UserVideosService _videosService = UserVideosService();
int get postsCount => myVideos.length;
  @override
  void onInit() {
    super.onInit();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    refreshMyProfile();
    getMyVideos();
    loadUserData();
    getLikedReels();
    getSavedReels();
  }

  @override
  void onClose() {
    pulseController.dispose();
    super.onClose();
  }

  Future<void> refreshMyProfile() async {
    try {
      final res = await _api.get(
        '/getUserProfile/$userId?currentUserId=$userId',
      );

      if (res['success'] == true) {
        final data = res['data'];

        followersCount.value = data['followersCount'];
        followingCount.value = data['followingCount'];
      }
    } catch (e) {
      print('Error refreshing profile: $e');
      Get.snackbar(
        'Error',
        'Failed to refresh profile',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> getMyVideos() async {
    final videos = await _videosService.getUserVideos(userId);
    myVideos.assignAll(videos);
  }

  Future<void> getLikedReels({bool loadMore = false}) async {
    if (!loadMore) {
      likedPage.value = 1;
      likedReelsUrls.clear();
      hasMoreLiked.value = true;
    }

    if (!hasMoreLiked.value) return;

    final videos = await _videosService.getLikedReels(
      userId,
      likedPage.value,
      10,
    );

    if (videos.isEmpty) {
      hasMoreLiked.value = false;
    } else {
      likedPage.value++;
      likedReelsUrls.addAll(videos);
    }
  }

  Future<void> getSavedReels({bool loadMore = false}) async {
    if (!loadMore) {
      likedPage.value = 1;
      savedVideos.clear();
      hasMoreLiked.value = true;
    }

    if (!hasMoreLiked.value) return;

    final videos = await _videosService.getSavedReels(
      userId,
      likedPage.value,
      10,
    );

    if (videos.isEmpty) {
      hasMoreLiked.value = false;
    } else {
      likedPage.value++;
      savedVideos.addAll(videos);
    }
  }

  void loadUserData() async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;

      if (user != null) {
        username.value = user.displayName ?? ''; 
        email.value = user.email ?? '';
        profilePic.value = user.photoURL ?? '';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load profile data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
    if (index == 1 && likedReelsUrls.isEmpty) {
      getLikedReels();
    }
    if (index == 1 && savedVideos.isEmpty) {
      getSavedReels();
    }
  }

  List<dynamic> getVideosForCurrentTab() {
    switch (selectedTab.value) {
      case 0:
        return myVideos;
      case 1:
        return likedReelsUrls;
      case 2:
        return savedVideos;
      default:
        return myVideos;
    }
  }

  Future<void> editProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final imageUrl = await uploadToS3(image.path);

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (imageUrl == null) {
        Get.snackbar(
          'Error',
          'Image upload failed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      profilePic.value = imageUrl;
      await _auth.currentUser?.updatePhotoURL(imageUrl);

      Get.snackbar(
        'Success',
        'Profile picture updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      print('editProfilePicture error: $e');

      Get.snackbar(
        'Error',
        'Failed to update profile picture',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String?> uploadToS3(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      if (!await imageFile.exists()) return null;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_api.baseUrl}/upload/profile-pic'),
      );

      request.fields['userId'] = user.uid;

      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      final response = await http.Response.fromStream(await request.send());

      final data = jsonDecode(response.body);

      return data['url'];
    } catch (e) {
      print(e);
      return null;
    }
  }

  void editProfile() {
    final nameController = TextEditingController(text: username.value);
    final bioController = TextEditingController(text: bio.value);

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFFF8F9FB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.black54),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green.withOpacity(0.15),
                    backgroundImage:
                        profilePic.value.isNotEmpty
                            ? NetworkImage(profilePic.value)
                            : null,
                    child:
                        profilePic.value.isEmpty
                            ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.green,
                            )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              TextField(
                controller: nameController,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Colors.green,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        side: BorderSide(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newName = nameController.text.trim();
                        final newBio = bioController.text.trim();

                        username.value = newName;
                        bio.value = newBio;

                        Get.back();

                        await profileController.updateProfile(
                          newName,
                          newBio,
                          profilePic.value,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

 


  

  void handleLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.find<AuthenticationService>().logout();
              Get.back();
              Get.offAll(SplashScreen());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
