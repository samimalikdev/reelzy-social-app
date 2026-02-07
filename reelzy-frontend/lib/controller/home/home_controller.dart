import 'dart:async';

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shorts_app/controller/profile/profile_controller.dart';
import 'package:shorts_app/model/reel_model.dart';
import 'package:shorts_app/screen/search/search_screen.dart';
import 'package:shorts_app/service/deep_link_service.dart';
import 'package:video_player/video_player.dart';
import 'package:shorts_app/controller/media/media_controller.dart';

class VideoState {
  bool isInitialized;
  bool isPlaying;

  VideoState({this.isInitialized = false, this.isPlaying = false});
}

class HomeController extends GetxController with GetTickerProviderStateMixin {
  final RxInt currentIndex = 0.obs;
  final RxBool isFollowing = false.obs;
  final RxBool isLoading = true.obs;

  final RxMap<String, VideoState> videoStates = <String, VideoState>{}.obs;
  final Map<String, VideoPlayerController> videoControllers = {};
  String? currentPostid;
  final DeepLinkService _deepLinkService = Get.find<DeepLinkService>();

  late MediaController mediaController;

  List<ReelModel> get posts => mediaController.reels;

  Timer? _pageChangeTimer;

  @override
  void onInit() {
    super.onInit();
    mediaController = Get.find<MediaController>();

    print('my id ${FirebaseAuth.instance.currentUser!.uid}');

    _fetchAndLoadReels();
  }

  Future<void> getFollowStatus() async {
    try {

      // TODO: I will update this soon
      // This currently slows down the UI coz it fetches profiles one by one

      final profileController = Get.find<ProfileController>();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) return;

      final userIds = <String>{};
      for (final post in posts) {
        if (post.targetId != null && post.targetId!.isNotEmpty) {
          userIds.add(post.targetId!);
        }
      }

      print('Fetching follow status for ${userIds.length} users');

      for (final userId in userIds) {
        try {
          await profileController.getUserProfile(userId);
        } catch (e) {
          print('Error fetching profile for $userId: $e');
        }
      }
    } catch (e) {
      print('Erro status: $e');
    }
  }

  void createVideoController(String postId, String videoUrl) {
    videoControllers[postId]?.dispose();

    VideoPlayerController controller;
    if (videoUrl.startsWith('http') || videoUrl.startsWith('https')) {
      controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    } else {
      controller = VideoPlayerController.asset(videoUrl);
    }

    videoControllers[postId] = controller;
    videoStates[postId] = VideoState();

    controller
        .initialize()
        .then((_) {
          controller.setLooping(true);
          if (videoStates.containsKey(postId)) {
            videoStates[postId] = VideoState(isInitialized: true);
            videoStates.refresh();
          }
        })
        .catchError((error) {
          print('Error video for $postId: $error');
        });
  }

  void preloadNextVideos(int currentIndex) {
    final indicesToLoad = [
      if (currentIndex > 0) currentIndex - 1,
      currentIndex,
      if (currentIndex < posts.length - 1) currentIndex + 1,
    ];

    for (final index in indicesToLoad) {
      final post = posts[index];
      if (!videoControllers.containsKey(post.id) && post.videoUrl != null) {
        createVideoController(post.id, post.videoUrl!);
      }
    }

    disposeOldVideos(currentIndex);
  }

  void disposeOldVideos(int currentIndex) {
    final keysToRemove = <String>[];

    videoControllers.forEach((key, controller) {
      final postIndex = posts.indexWhere((post) => post.id == key);
      if (postIndex != -1 &&
          (postIndex < currentIndex - 2 || postIndex > currentIndex + 2)) {
        controller.dispose();
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      videoControllers.remove(key);
      videoStates.remove(key);
    }
  }

  void onPageChanged(int index) {
    currentIndex.value = index;

    if (index >= posts.length - 3 &&
        mediaController.hasMoreData.value &&
        !mediaController.isLoadingMore.value) {
      print('Near end of feed, loading more reels...');
      mediaController.loadMoreMedia();
    }

    _pageChangeTimer?.cancel();
    _pageChangeTimer = Timer(const Duration(milliseconds: 150), () {
      final post = posts[index];
      playVideo(post.id);
      preloadNextVideos(index);
    });
  }

  void playVideo(String postId) {
    final controller = videoControllers[postId];
    if (controller != null && controller.value.isInitialized) {
      _pauseAllVideos();
      controller.play();

      if (videoStates.containsKey(postId)) {
        final currentState = videoStates[postId]!;
        videoStates[postId] = VideoState(
          isInitialized: currentState.isInitialized,
          isPlaying: true,
        );
        videoStates.refresh();
      }

      currentPostid = postId;
    }
  }

  void pauseVideo(String postId) {
    final controller = videoControllers[postId];
    if (controller != null && controller.value.isInitialized) {
      controller.pause();

      if (videoStates.containsKey(postId)) {
        final currentState = videoStates[postId]!;
        videoStates[postId] = VideoState(
          isInitialized: currentState.isInitialized,
          isPlaying: false,
        );
        videoStates.refresh();
      }
    }
  }

  void _pauseAllVideos() {
    for (final entry in videoStates.entries) {
      if (entry.value.isPlaying) {
        final controller = videoControllers[entry.key];
        controller?.pause();

        videoStates[entry.key] = VideoState(
          isInitialized: entry.value.isInitialized,
          isPlaying: false,
        );
      }
    }
    videoStates.refresh();
  }

  void toggleVideoPlayPause(String postId) {
    final controller = videoControllers[postId];
    if (controller != null && controller.value.isInitialized) {
      final currentState = videoStates[postId];
      if (currentState?.isPlaying ?? false) {
        pauseVideo(postId);
      } else {
        playVideo(postId);
      }
    }
  }

  void toggleFollow() {
    isFollowing.value = !isFollowing.value;
  }

  void openSearch() {
    Get.to(() => SearchUsersScreen());
  }

  void openComments() {
    print('Opening comments...');
  }

  Future<void> shareReel(ReelModel post) async {
    await _deepLinkService.shareReel(post);
  }

  Future<void> _fetchAndLoadReels() async {
    try {
      isLoading.value = true;

      await mediaController.fetchMedia();

      if (posts.isNotEmpty) {
        await getFollowStatus();

        preloadNextVideos(0);
      }
    } catch (e) {
      print('Error loading reels: $e');
      Get.snackbar(
        'Error',
        'Failed to load reels',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshReels() async {
    print('Refreshing reels...');

    for (final controller in videoControllers.values) {
      controller.dispose();
    }
    videoControllers.clear();
    videoStates.clear();

    await mediaController.refreshMedia();

    if (posts.isNotEmpty) {
      await getFollowStatus();
      preloadNextVideos(0);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (posts.isNotEmpty) {
          playVideo(posts[0].id);
        }
      });
    }
  }

  @override
  void onClose() {
    _pageChangeTimer?.cancel();

    for (final controller in videoControllers.values) {
      controller.dispose();
    }
    videoControllers.clear();
    videoStates.clear();

    super.onClose();
  }
}
