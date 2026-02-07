// lib/services/deep_link_service.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:app_links/app_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shorts_app/model/post_model.dart';
import 'package:shorts_app/model/reel_model.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/controller/media/media_controller.dart';
import 'package:shorts_app/controller/profile/profile_controller.dart';
import 'package:shorts_app/controller/profile/follow_controller.dart';
import 'package:shorts_app/screen/fullscreen_video_screen.dart';
import 'package:shorts_app/screen/profile/profile_screen.dart';

class DeepLinkService extends GetxService {
  late AppLinks appLinks;
  StreamSubscription? linkSubscription;
  
  final RxBool isInitialized = false.obs;
  final RxString lastDeepLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initDeepLinks();
  }

  @override
  void onClose() {
    linkSubscription?.cancel();
    super.onClose();
  }

  Future<void> initDeepLinks() async {
    try {
      appLinks = AppLinks();

      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        handleDeepLink(initialLink.toString());
      }

      linkSubscription = appLinks.uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
          handleDeepLink(uri.toString());
          }
        },
        onError: (err) {
          print('Deep link error: $err');
        },
      );

      isInitialized.value = true;
    } catch (e) {
      print('Error: $e');
    }
  }

  void handleDeepLink(String link) {
    lastDeepLink.value = link;
    print('deep link: $link');

    final uri = Uri.parse(link);
    
    if (uri.scheme == 'shortsapp' && uri.host == 'reel') {
      if (uri.pathSegments.isNotEmpty) {
        final reelId = uri.pathSegments[0];
        navigateToReel(reelId);
      }
    } 
    else if (uri.scheme == 'shortsapp' && uri.host == 'profile') {
      if (uri.pathSegments.isNotEmpty) {
        final userId = uri.pathSegments[0];
        navigateToProfile(userId);
      }
    }
  }

  Future<void> navigateToReel(String reelId) async {
    print('Navigating to reel: $reelId');
    
    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        barrierDismissible: false,
      );

      final mediaController = Get.find<MediaController>();
      
      ReelModel? reel = mediaController.getReelById(reelId);
      
      if (reel == null) {
        
        await mediaController.fetchMedia();
        
        reel = mediaController.getReelById(reelId);
      }
      
      Get.back();
      
      if (reel != null) {
        Get.to(() => FullscreenVideoScreen(reel: reel!));
      } else {
        Get.snackbar(
          'Error',
          'Reel not found',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
      
    } catch (e) {
      Get.back(); 
      print('Error loading reel: $e');
      
    }
  }

  Future<void> navigateToProfile(String userId) async {
    
    try {
      

      final profileController = Get.find<ProfileController>();
      final followController = Get.find<FollowController>();
      
      await profileController.getUserProfile(userId);
      
      Get.back(); 
      
      final userProfile = UserProfile(
        userId: userId,
        username: profileController.username.value,
        profilePic: profileController.profilePic.value, 
        bio: '',
        isFollowing: profileController.isFollowing.value,
        followersCount: profileController.followersCount.value,
        followingCount: profileController.followingCount.value,
      );
      
      Get.to(() => ProfileScreen(
        userId: userId,
        user: userProfile,
      ));
      
    } catch (e) {
      Get.back();
      print('Error loading profile: $e');
    
    }
  }

  String generateReelDeepLink(String reelId) {
    return 'shortsapp://reel/$reelId';
  }

  String generateProfileDeepLink(String userId) {
    return 'shortsapp://profile/$userId';
  }

  Future<void> shareReel(dynamic reel) async {
    try {
      String reelId;
      String username;
      String description;
      List<String> hashtags = [];
      
      if (reel is ReelModel) {
        reelId = reel.id;
        username = reel.username;
        description = reel.description;
        hashtags = reel.hashtags;
      } else if (reel is ReelModel) {
        reelId = reel.id;
        username = reel.username ?? 'Unknown';
        description = reel.description ?? '';
        hashtags = []; 
      } else {
        throw Exception('Invalid reel type');
      }
      
      final deepLink = generateReelDeepLink(reelId);
      final shortUrl = await shortenUrl(deepLink);
      
      final hashtagsText = hashtags.isNotEmpty 
          ? '\n\n${hashtags.map((tag) => '#$tag').join(' ')}'
          : '';
      
      final shareText = '''
🎬 Check out this amazing reel by $username!

$description

Watch now: $shortUrl$hashtagsText

#Reelzy
''';

      await Share.share(
        shareText,
        subject: 'Check out this reel on Reelzy!',
      );

      print('Reel shared: $reelId');
      
      if (reel is ReelModel) {
        final mediaController = Get.find<MediaController>();
        final cachedReel = mediaController.getReelById(reelId);
        if (cachedReel != null) {
          cachedReel.shareCount += 1;
          mediaController.reels.refresh();
        }
      }
      
    } catch (e) {
      print('Error sharing reel: $e');
    }
  }

  Future<void> shareProfile(String userId, String username, {String? profilePic}) async {
    try {
      final deepLink = generateProfileDeepLink(userId);
      final shortUrl = await shortenUrl(deepLink);
      
      final shareText = '''
👤 Check out $username on Reelzy!

Follow $username and explore their amazing content!

Profile: $shortUrl

#Reelzy
''';

      await Share.share(
        shareText,
        subject: 'Follow $username on Reelzy!',
      );
      
    } catch (e) {
      print('Error sharing profile: $e');

    }
  }

  Future<String> shortenUrl(String longUrl) async {
    try {
      final encodedUrl = Uri.encodeComponent(longUrl);
      final response = await http.get(
        Uri.parse('https://tinyurl.com/api-create.php?url=$encodedUrl'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        return response.body;
      }
    } catch (e) {
      print('URL failed: $e');
    }
    
    return longUrl;
  }
}