import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/comment/comment_controller.dart';
import 'dart:ui'; 

import 'package:shorts_app/controller/post/post_controller.dart';
import 'package:shorts_app/controller/profile/profile_controller.dart';
import 'package:shorts_app/controller/story/story_contoller.dart';
import 'package:shorts_app/model/post_model.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/screen/message/chat_screen.dart';
import 'package:shorts_app/screen/profile/profile_screen.dart';
import 'package:shorts_app/screen/story_viewer_screen.dart';
import 'package:shorts_app/screen/widget/add_story_sheet.dart';
import 'package:shorts_app/screen/widget/comment_widget.dart';
import 'package:shorts_app/service/authentication.dart';
import 'package:shorts_app/shared/widgets/add_post_sheet.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/shared/widgets/report_sheet.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  late PostsController postsController;
  late ScrollController scrollController;
  late StoryController storyController;
  late ProfileController profileController;
  final Color tealDark = const Color(0xFF1F4E56);
  final Color tealLight = const Color(0xFF4A848F);
  final Color bgGrey = const Color(0xFFF2F4F7);

  @override
  void initState() {
    super.initState();
    postsController = Get.put(PostsController());
    storyController = Get.put(StoryController());
    profileController = Get.find<ProfileController>();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);

    storyController.getStoriesFeed(); 
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      if (postsController.hasMorePosts && !postsController.isLoadingMore) {
        postsController.loadMorePosts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: Obx(() {
                if (postsController.isLoading &&
                    postsController.posts.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: tealDark),
                  );
                }

                if (postsController.error.isNotEmpty &&
                    postsController.posts.isEmpty) {
                  return _buildErrorState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await postsController.refreshPosts();
                    await storyController.refreshStories();
                  },
                  color: tealDark,
                  backgroundColor: Colors.white,
                  displacement: 20,
                  child: ListView.builder(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount:
                        postsController.posts.length +
                        1 +
                        (postsController.hasMorePosts ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildStoriesSection();
                      }

                      int postIndex = index - 1;
                      if (postIndex == postsController.posts.length) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: tealDark,
                              ),
                            ),
                          ),
                        );
                      }

                      final post = postsController.posts[postIndex];

                      UserProfile user = UserProfile(
                        userId: post.userId,
                        username: post.username ?? 'Unknown',
                        profilePic:
                            post.userAvatar ??
                            'https://i.pravatar.cc/150?img=1',
                        bio: post.userBio ?? '',
                        followersCount: post.followersCount,
                        followingCount: post.followingCount,
                      );

                      return _buildPostCard(post, user);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 115,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Obx(() {
        Map<String, List<dynamic>> groupedStories = {};

        for (var story in storyController.storiesFeed) {
          String userId = story['userId'] ?? '';
          if (!groupedStories.containsKey(userId)) {
            groupedStories[userId] = [];
          }
          groupedStories[userId]!.add(story);
        }

        String currentUserId = '';

        List<MapEntry<String, List<dynamic>>> storyEntries =
            groupedStories.entries.toList();

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: storyEntries.length + 1, 
          itemBuilder: (context, index) {
            if (index == 0) {
              return _StoryAvatar(
                imageUrl: AuthenticationService().photoURL ?? 'https://i.pravatar.cc/150?img=3',
                username: 'My Story',
                isYourStory: true,
                hasStory: false,
                tealDark: tealDark,
                tealLight: tealLight,
                onTap: () {
                  Get.bottomSheet(
                    AddStorySheet(),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                  );
                },
              );
            }

            int storyIndex = index - 1;
            var entry = storyEntries[storyIndex];
            String userId = entry.key;
            List<dynamic> userStories = entry.value;

            var firstStory = userStories.first;
            String username = firstStory['username'] ?? 'User';
            String profilePic =
                firstStory['profilePic'] ??
                'https://i.pravatar.cc/150?img=${index + 1}';

            return _StoryAvatar(
              imageUrl: profilePic,
              username: username,
              isYourStory: false,
              hasStory: true,
              tealDark: tealDark,
              tealLight: tealLight,
              onTap: () {
                Get.to(
                  () => StoryViewerScreen(stories: userStories),
                  transition: Transition.fade,
                );
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Explore',
            style: GoogleFonts.outfit(
              color: Colors.black87,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              _buildGlassyIcon(Icons.add_circle, () {
                Get.bottomSheet(
                  AddPostSheet(),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  enableDrag: true,
                  isDismissible: true,
                );
              }),
              const SizedBox(width: 12),
              _buildGlassyIcon(Icons.mark_chat_unread_sharp, () {
                Get.to(ChatListScreen());
              }, hasBadge: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyIcon(
    IconData icon,
    VoidCallback onTap, {
    bool hasBadge = false,
  }) {
    return Stack(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Icon(icon, color: Colors.grey[800], size: 24),
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPostCard(Post post, UserProfile user) {
    void onProfileTap() async {
      Get.delete<ProfileController>();

      final newController = Get.put(ProfileController());

      await newController.getUserProfile(user.userId);

      Get.to(() => ProfileScreen(userId: post.userId, user: user));
    }

    String displayUsername =
        post.username?.isNotEmpty == true ? post.username! : 'Unknown';
    String timeAgo =
        post.createdAt != null ? post.timeAgo ?? 'Just now' : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F5259).withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [tealDark.withOpacity(0.8), tealLight],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          (post.userAvatar != null &&
                                  post.userAvatar!.isNotEmpty)
                              ? post.userAvatar!
                              : 'https://i.pravatar.cc/150?img=1',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onProfileTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayUsername,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF9FA5AA),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[400]),
                  onPressed: () {
                    Get.bottomSheet(
                      ReportSheet(targetId: post.id, targetType: 'post'),
                      isScrollControlled: true,
                    );
                  },
                ),
              ],
            ),
          ),

          if (post.hasImage && post.imageUrl != null)
            GestureDetector(
              onTap: () => _showImageDialog(context, post.imageUrl!),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(post.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF424242),
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildPillAction(
                      icon:
                          post.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                      color:
                          post.isLiked
                              ? const Color(0xFFFF5252)
                              : Colors.black87,
                      label: '${post.likesCount}',
                      isActive: post.isLiked,
                      onTap: () => postsController.toggleLike(post),
                    ),
                    const SizedBox(width: 12),
                    _buildPillAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: Colors.black87,
                      label: '${post.commentsCount}',
                      isActive: false,
                      onTap: () {
                        Get.bottomSheet(
                          CommentsSheet<CommentsController>(
                            id: post.id,
                            controller: CommentsController(postId: post.id),
                          ),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.black87,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(
                        post.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: post.isSaved ? tealDark : Colors.black87,
                      ),
                      onPressed: () => postsController.toggleSave(post),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillAction({
    required IconData icon,
    required Color color,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                isActive
                    ? color.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tealLight.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.refresh_rounded, color: tealDark, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            postsController.error,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => postsController.refreshPosts(),
            style: ElevatedButton.styleFrom(
              backgroundColor: tealDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder:
          (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String imageUrl;
  final String username;
  final bool isYourStory;
  final bool hasStory;
  final Color tealDark;
  final Color tealLight;
  final VoidCallback? onTap; 

  const _StoryAvatar({
    required this.imageUrl,
    required this.username,
    required this.tealDark,
    required this.tealLight,
    this.isYourStory = false,
    this.hasStory = true,
    this.onTap, 
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        hasStory
                            ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [tealDark, tealLight],
                            )
                            : null,
                    color: hasStory ? null : Colors.grey[300],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5), 
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white, 
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2.5), 
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                        ),
                      ),
                    ),
                  ),
                ),
                if (isYourStory)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: tealDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              username,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey[800],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
