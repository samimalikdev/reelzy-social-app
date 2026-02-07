import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/controller/profile/follow_controller.dart';
import 'package:shorts_app/controller/profile/profile_controller.dart';
import 'package:shorts_app/model/user_profile.dart';
import 'package:shorts_app/screen/profile/profile_screen.dart';
import 'package:shorts_app/service/authentication.dart';

class SearchUsersController extends GetxController {
  final ApiController api = ApiController();

  var users = <UserProfile>[].obs;
  var isLoading = false.obs;
  var hasMore = true.obs;

  var page = 1;
  final int limit = 15;

  var searchQuery = ''.obs;

  late final String currentUserId;

  @override
  void onInit() {
    super.onInit();
    currentUserId = Get.find<AuthenticationService>().userId!;

    ever(searchQuery, (_) {
      page = 1;
      users.clear();
      hasMore.value = true;
      fetchUsers();
    });

    fetchUsers();
  }

  Future<void> fetchUsers() async {
    if (!hasMore.value || isLoading.value) return;

    try {
      isLoading.value = true;

      final res = await api.get(
        '/getUsers'
        '?page=$page'
        '&limit=$limit'
        '&search=${searchQuery.value}'
        '&excludeUserId=$currentUserId',
      );

      if (res['success'] == true) {
        final List<UserProfile> fetched =
            (res['users'] as List).map((e) => UserProfile.fromJson(e)).toList();

        users.addAll(fetched);
        hasMore.value = res['hasMore'] ?? false;
        page++;
      }
    } catch (e) {
      print('Search users error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void refresh() {
    page = 1;
    users.clear();
    hasMore.value = true;
    fetchUsers();
  }
}

class SearchUsersScreen extends StatelessWidget {
  SearchUsersScreen({super.key});

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchUsersController());
    
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        controller.fetchUsers();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D7A4F), Color(0xFF3B9A65)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D7A4F).withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(
                            () => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Search Users',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${controller.users.length} users found',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Obx(
                        () => TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            controller.updateSearchQuery(value);
                          },
                          autofocus: true,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by name or username...',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF9FA5AA),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF2D7A4F),
                              size: 22,
                            ),
                            suffixIcon:
                                controller.searchQuery.value.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFF9FA5AA),
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          controller.updateSearchQuery('');
                                        },
                                      )
                                    : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.users.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2D7A4F),
                    ),
                  );
                }

                if (controller.users.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: controller.users.length +
                      (controller.hasMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == controller.users.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF2D7A4F),
                          ),
                        ),
                      );
                    }

                    final user = controller.users[index];
                    return _UserListTile(user: user);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2D7A4F).withOpacity(0.1),
                  const Color(0xFF3B9A65).withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 60,
              color: const Color(0xFF2D7A4F).withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No users found',
            style: GoogleFonts.inter(
              color: const Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different keyword',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final UserProfile user;

  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
           Get.to(ProfileScreen(userId: user.userId, user: user,));
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2D7A4F).withOpacity(0.3),
                            const Color(0xFF3B9A65).withOpacity(0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2D7A4F).withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: user.profilePic != null &&
                                  user.profilePic!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(user.profilePic!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: user.profilePic == null ||
                                  user.profilePic!.isEmpty
                              ? const Color(0xFF2D7A4F).withOpacity(0.2)
                              : null,
                        ),
                        child: user.profilePic == null ||
                                user.profilePic!.isEmpty
                            ? Center(
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF2D7A4F),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                _FollowButton(userId: user.userId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final String userId;

  const _FollowButton({required this.userId});

  @override
  Widget build(BuildContext context) {
final followController = Get.find<FollowController>();

    return Obx(() {
      final isFollowing = followController.followMap[userId] ?? false;

      return Container(
        decoration: BoxDecoration(
          gradient: isFollowing
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2D7A4F),
                    Color(0xFF3B9A65),
                  ],
                ),
          color: isFollowing ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(12),
          border: isFollowing
              ? Border.all(color: Colors.grey[400]!, width: 1)
              : null,
          boxShadow: [
            BoxShadow(
              color: isFollowing
                  ? Colors.black.withOpacity(0.05)
                  : const Color(0xFF2D7A4F).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              followController.toggleFollow(userId);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isFollowing ? Icons.check_rounded : Icons.add_rounded,
                    color: isFollowing ? Colors.grey[700] : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: GoogleFonts.inter(
                      color: isFollowing ? Colors.grey[700] : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}