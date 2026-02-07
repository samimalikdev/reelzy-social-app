import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/home/home_controller.dart';
import 'dart:ui';

import 'package:shorts_app/controller/media/media_controller.dart';
import 'package:shorts_app/controller/profile/follow_controller.dart';
import 'package:shorts_app/controller/profile/profile_controller.dart';
import 'package:shorts_app/model/reel_model.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/screen/call/call_screen.dart';
import 'package:shorts_app/screen/fullscreen_video_screen.dart';
import 'package:shorts_app/screen/home/home_screen.dart';
import 'package:shorts_app/screen/widget/incoming_call.dart';
import 'package:shorts_app/service/chat_service.dart';
import 'package:shorts_app/service/deep_link_service.dart';
import 'package:shorts_app/shared/widgets/report_sheet.dart';

import 'package:video_player/video_player.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;
  final UserProfile user;

  ProfileScreen({super.key, this.userId, required this.user});

  final Color bgLight = const Color(0xFFF8F9FB);
  final Color textDark = const Color(0xFF1A1A1A);
  final Color textGrey = const Color(0xFF6B7280);

  final Color accentGreen = const Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    final followController = Get.find<FollowController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId != null) {
        controller.getUserProfile(userId!);
      }
    });

    return Scaffold(
      backgroundColor: bgLight,
      body: Obx(() {
        return Stack(
          children: [
            Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.05),
                    ),
                  ),
                ),
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      expandedHeight: 0,
                      floating: true,
                      pinned: true,
                      leading: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed: () => Get.back(),
                      ),
                      flexibleSpace: ClipRRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.black87,
                              size: 20,
                            ),
                            offset: const Offset(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: Colors.white,
                            elevation: 4,
                            itemBuilder:
                                (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'Report',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.report,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Report User',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                            onSelected: (String value) {
                              Get.bottomSheet(
                                ReportSheet(
                                  targetId: user.userId,
                                  targetType: 'user',
                                ),
                                isScrollControlled: true,
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: controller.pulseController,
                              builder: (context, child) {
                                return Container(
                                  height: 140,
                                  width: 140,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(70),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple,
                                        Colors.pink,
                                        Colors.cyan,
                                        Colors.orange,
                                        Colors.purple,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      transform: GradientRotation(
                                        controller.pulseController.value * 6.28,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(64),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        (user.profilePic != null &&
                                                user.profilePic!.isNotEmpty)
                                            ? user.profilePic!
                                            : 'https://i.pravatar.cc/150?img=1',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.username,
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.verified,
                                  color: accentGreen,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Text(
                              'Verified Creator',
                              style: TextStyle(
                                color: textGrey,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 28),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _EnhancedStatsItem(
                                    title: 'Following',
                                    count:
                                        controller.followingCount.value
                                            .toString(),
                                    textColor: textDark,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                  _EnhancedStatsItem(
                                    title: 'Followers',
                                    count:
                                        controller.followersCount.value
                                            .toString(),
                                    textColor: textDark,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                  Obx(() {
                                    return _EnhancedStatsItem(
                                      title: 'Videos',
                                      count: controller.postsCount.toString(),
                                      textColor: textDark,
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Obx(() {
                                    if (userId == null) {
                                      return const SizedBox.shrink();
                                    }

                                    final isFollowing =
                                        followController.followMap[userId!] ??
                                        controller.isFollowing.value;

                                    return Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient:
                                            isFollowing
                                                ? null
                                                : LinearGradient(
                                                  colors: [
                                                    Colors.green.shade800,
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                ),
                                        color:
                                            isFollowing
                                                ? Colors.grey[300]
                                                : null,
                                        borderRadius: BorderRadius.circular(25),
                                        border:
                                            isFollowing
                                                ? Border.all(
                                                  color: Colors.grey[400]!,
                                                  width: 1.5,
                                                )
                                                : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                isFollowing
                                                    ? Colors.black.withOpacity(
                                                      0.05,
                                                    )
                                                    : Colors.green.withOpacity(
                                                      0.3,
                                                    ),
                                            blurRadius: 15,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          controller.toggleFollow(userId!);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isFollowing
                                                  ? Icons.check_rounded
                                                  : Icons.add_rounded,
                                              color:
                                                  isFollowing
                                                      ? Colors.grey[700]
                                                      : Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isFollowing
                                                  ? 'Following'
                                                  : 'Follow',
                                              style: TextStyle(
                                                color:
                                                    isFollowing
                                                        ? Colors.grey[700]
                                                        : Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(width: 12),

                                _LightActionButton(
                                  icon: Icons.message_rounded,
                                  onTap: () {
                                    controller.navigateToMessages(
                                      user.username,
                                      user,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                _LightActionButton(
                                  icon: Icons.share_rounded,
                                  onTap: () {
                                    final deepLinkService =
                                        Get.find<DeepLinkService>();
                                    deepLinkService.shareProfile(
                                      user.userId,
                                      user.username,
                                      profilePic: user.profilePic,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            if (user.bio != null && user.bio!.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  user.bio!,
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Obx(
                          () => Row(
                            children: [
                              _LightTabButton(
                                title: 'Videos',
                                icon: Icons.play_circle_filled_rounded,
                                isSelected: controller.selectedTab.value == 0,
                                onTap: () => controller.changeTab(0),
                              ),
                              _LightTabButton(
                                title: 'Liked',
                                icon: Icons.favorite_rounded,
                                isSelected: controller.selectedTab.value == 1,
                                onTap: () => controller.changeTab(1),
                              ),
                              _LightTabButton(
                                title: 'Saved',
                                icon: Icons.bookmark_rounded,
                                isSelected: controller.selectedTab.value == 2,
                                onTap: () => controller.changeTab(2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Obx(() {
                      if (controller.isLoading.value) {
                        return const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                          ),
                        );
                      }

                      final videos = controller.getVideosForCurrentTab();

                      if (videos.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    controller.selectedTab.value == 0
                                        ? Icons.video_library_outlined
                                        : controller.selectedTab.value == 1
                                        ? Icons.favorite_border
                                        : Icons.bookmark_border,
                                    size: 64,
                                    color: textGrey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    controller.selectedTab.value == 0
                                        ? 'No videos yet'
                                        : controller.selectedTab.value == 1
                                        ? 'No liked videos'
                                        : 'No saved videos',
                                    style: TextStyle(
                                      color: textGrey,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 90),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.7,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _EnhancedVideoThumbnail(
                              video: videos[index],
                              index: index,
                            ),
                            childCount: videos.length,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),

            if (controller.isLoading.value)
              Container(
                color: bgLight.withOpacity(0.9),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: accentGreen,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading profile...',
                          style: TextStyle(
                            color: textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _EnhancedStatsItem extends StatelessWidget {
  final String title;
  final String count;
  final Color textColor;

  const _EnhancedStatsItem({
    required this.title,
    required this.count,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LightActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _LightActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }
}

class _LightTabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LightTabButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.green[700] : Colors.grey[400],
                size: 20,
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancedVideoThumbnail extends StatelessWidget {
  final ReelModel video;
  final int index;

  const _EnhancedVideoThumbnail({required this.video, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => FullscreenVideoScreen(reel: video));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (video.thumbnail != null && video.thumbnail!.isNotEmpty)
                Image.network(
                  video.thumbnail!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.video_library,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.video_library,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                ),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        _formatCount(video.likeCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
