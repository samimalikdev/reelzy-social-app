import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/comment/comment_controller.dart';
import 'package:shorts_app/controller/comment/reel_comments_controller.dart';
import 'package:shorts_app/controller/home/home_controller.dart';
import 'package:shorts_app/controller/post/post_controller.dart';
import 'package:shorts_app/controller/profile/follow_controller.dart';
import 'package:shorts_app/controller/profile/profile_controller.dart';
import 'package:shorts_app/model/post_model.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/screen/profile/profile_screen.dart';
import 'package:shorts_app/screen/widget/comment_widget.dart';
import 'package:shorts_app/shared/widgets/report_sheet.dart';
import 'package:uuid/uuid.dart';

import 'package:video_player/video_player.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/controller/auth/main_auth_controller.dart';
import 'package:shorts_app/controller/media/media_controller.dart';

class HomeScreen extends StatelessWidget {
  final HomeController controller = Get.find<HomeController>();
  final MainAuthController authController = Get.find<MainAuthController>();
  final MediaController mediaController = Get.find<MediaController>();
  final PostsController postsController = Get.find<PostsController>();
  final FollowController followController = Get.find<FollowController>();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: controller.refreshReels,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (controller.posts.isEmpty) {
            return const Center(
              child: Text(
                'No reels available',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return PageView.builder(
            scrollDirection: Axis.vertical, 
            onPageChanged:
                controller
                    .onPageChanged, 
            itemCount: controller.posts.length,
            physics: const BouncingScrollPhysics(),
            pageSnapping: true,
            itemBuilder: (context, index) {
              final post = controller.posts[index];

              return KeyedSubtree(
                key: ValueKey(post.id),
                child: Stack(
                  children: [
                    Obx(() {
                      final state = controller.videoStates[post.id];
                      final isInitialized = state?.isInitialized ?? false;

                      if (!isInitialized) {
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      final videoController =
                          controller.videoControllers[post.id];
                      if (videoController == null)
                        return const SizedBox.shrink();

                      return SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: videoController.value.size.width,
                            height: videoController.value.size.height,
                            child: VideoPlayer(videoController),
                          ),
                        ),
                      );
                    }),

                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => controller.toggleVideoPlayPause(post.id),
                        child: Container(
                          color: Colors.transparent,
                          child: Obx(() {
                            final state = controller.videoStates[post.id];
                            final isPlaying = state?.isPlaying ?? false;
                            return AnimatedOpacity(
                              opacity: isPlaying ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: const Center(
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 80,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),



                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Get.bottomSheet(
                                  ReportSheet(
                                    targetId: post.id,
                                    targetType: 'reel',
                                  ),
                                  isScrollControlled: true,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(
                                  Icons.report_gmailerrorred,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),

                            const Spacer(),

                            GestureDetector(
                              onTap: controller.openSearch,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Positioned(
                      left: 20,
                      bottom: 170,
                      right: 100,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                              if (post.isVerified) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ],

                              const SizedBox(width: 10),
                              Obx(() {
                                final isFollowing =
                                    followController.followMap[post.targetId] ??
                                    false;

                                return GestureDetector(
                                  onTap: () {
                                    followController.toggleFollow(
                                      post.targetId!,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isFollowing
                                              ? Colors.grey.withOpacity(0.5)
                                              : Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Text(
                              post.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.4,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children:
                                post.hashtags
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        child: Text(
                                          '#$tag',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 170,
                      right: 16,
                      child: Obx(() {
                        final isLiked = mediaController.isReelLiked(post.id);
                        final isSaved = mediaController.isReelSaved(post.id);

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            actionIcon(
                              icon:
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                              label: post.likeCount.toString(),
                              iconColor: isLiked ? Colors.red : Colors.white,
                              onTap: () {
                                if (isLiked) {
                                  // authController.interactions
                                  //     .removeFromLikedVideos(post.id);
                                } else {
                                  mediaController.toggleLike(post);
                                }
                              },
                            ),

                            const SizedBox(height: 20),

                            actionIcon(
                              icon: Icons.comment_rounded,
                              label: post.commentCount.toString(),
                              onTap: () {
                                Get.bottomSheet(
                                  CommentsSheet<ReelCommentsController>(
                                    id: post.id,
                                    controller: ReelCommentsController(
                                      reelId: post.id,
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            actionIcon(
                              icon:
                                  isSaved
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                              label: post.saveCount.toString(),
                              iconColor: isSaved ? Colors.amber : Colors.white,
                              onTap: () {
                                if (isSaved) {
                                } else {
                                  mediaController.toggleSave(post);
                                }
                              },
                            ),

                            const SizedBox(height: 20),

                            actionIcon(
                              icon: Icons.share_rounded,
                              label: post.shareCount.toString(),
                              iconColor: Colors.green,
                              onTap: () {
                                controller.shareReel(post);
                                mediaController.shareReel(post);
                              },
                            ),

                            const SizedBox(height: 24),
                            InkWell(
                              onTap: () {
                                final profileController =
                                    Get.find<ProfileController>();

                                profileController.resetProfile();
                                Get.to(
                                  () => ProfileScreen(
                                    userId: post.targetId,
                                    user: UserProfile(
                                      userId: post.targetId ?? '',
                                      username: post.username,
                                      profilePic: post.profilePic!,
                                      bio: '',
                                      isFollowing:
                                          followController.followMap[post
                                              .targetId] ??
                                          false,
                                      followersCount:
                                          followController
                                              .followersCountMap[post
                                              .targetId] ??
                                          0,
                                      followingCount:
                                          followController
                                              .followingCountMap[post
                                              .targetId] ??
                                          0,
                                    ),
                                  ),
                                );

                                if (post.targetId != null) {
                                  profileController.getUserProfile(
                                    post.targetId!,
                                  );
                                }
                              },
                              child: Container(
                                height: 56,
                                width: 56,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.purple,
                                      Colors.pink,
                                      Colors.orange,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      post.profilePic ??
                                          'https://i.pravatar.cc/150?img=6',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                    Positioned(
                      bottom: 100,
                      left: 20,
                      right: 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    post.musicTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                               
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget actionIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
      Get.put<ApiController>(ApiController(), permanent: true);
    Get.lazyPut<MediaController>(() => MediaController(), fenix: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<MainAuthController>(() => MainAuthController(), fenix: true);
    Get.lazyPut<PostsController>(() => PostsController(), fenix: true);
        Get.put<FollowController>(FollowController(), permanent: true);
            Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    
  }
}
