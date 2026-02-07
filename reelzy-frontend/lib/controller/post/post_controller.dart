import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/model/post_model.dart';

class PostsController extends GetxController {
  static PostsController get to => Get.find<PostsController>();

  final ApiController _apiController = ApiController();

  final RxList<Post> _posts = <Post>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxString _error = ''.obs;
  final RxInt _currentPage = 1.obs;
  final RxInt _totalPages = 1.obs;
  final RxInt _totalPosts = 0.obs;
  final RxBool _hasMorePosts = true.obs;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading.value;
  bool get isLoadingMore => _isLoadingMore.value;
  String get error => _error.value;
  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  int get totalPosts => _totalPosts.value;
  bool get hasMorePosts => _hasMorePosts.value;

  @override
  void onInit() {
    super.onInit();
   // _loadFromIsar();
    fetchPosts();
  }

  /// ================= LOAD FROM ISAR =================
  // Future<void> _loadFromIsar() async {
  //   final isar = IsarService.isar;
  //   final localPosts = await isar.postEntitys.where().findAll();

  //   if (localPosts.isEmpty) return;

  //   _posts.assignAll(
  //     localPosts.map(
  //       (p) => Post(
  //         id: p.postId,
  //         userId: p.userId,
  //         content: p.content,

  //         imageUrl: p.imageUrl.isNotEmpty ? p.imageUrl : null,

  //         createdAt: p.createdAt,
  //         updatedAt: p.updatedAt,

  //         likesCount: p.likesCount,
  //         commentsCount: p.commentsCount,
  //         savesCount: p.savesCount,
  //         shareCount: p.shareCount,

  //         isLiked: p.isLiked,
  //         isSaved: p.isSaved,

  //         username: p.username,
  //         userAvatar: p.userAvatar,
  //         userBio: p.userBio,
  //         followersCount: p.followersCount,
  //         followingCount: p.followingCount,
  //       ),
  //     ),
  //   );
  // }

  Future<void> fetchPosts({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage.value = 1;
        _hasMorePosts.value = true;
      }

      _currentPage.value == 1
          ? _isLoading.value = true
          : _isLoadingMore.value = true;

      _error.value = '';

      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final response = await _apiController.get(
        '/getPosts?page=${_currentPage.value}&limit=10&userId=$userId',
      );

      if (response['success'] == true) {
        final List<Post> newPosts =
            (response['data'] as List).map((e) => Post.fromJson(e)).toList();

        if (_currentPage.value == 1 || refresh) {
          _posts.assignAll(newPosts);
        } else {
          _posts.addAll(newPosts);
        }

        _currentPage.value = response['currentPage'] ?? 1;
        _totalPages.value = response['totalPages'] ?? 1;
        _totalPosts.value = response['totalPosts'] ?? 0;
        _hasMorePosts.value = _currentPage.value < _totalPages.value;

     //   await _saveToIsar(newPosts);
      } else {
        _error.value = response['error'] ?? 'Failed to fetch posts';
      }
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
      _isLoadingMore.value = false;
    }
  }

  /// ================= SAVE TO ISAR =================
  // Future<void> _saveToIsar(List<Post> posts) async {
  //   final isar = IsarService.isar;

  //   await isar.writeTxn(() async {
  //     for (final post in posts) {
  //       final entity =
  //           PostEntity()
  //             ..postId = post.id
  //             ..userId = post.userId
  //             ..content = post.content
  //             ..imageUrl = post.imageUrl ?? ''
  //             ..username = post.username ?? ''
  //             ..userAvatar = post.userAvatar ?? ''
  //             ..userBio = post.userBio ?? ''
  //             ..followersCount = post.followersCount
  //             ..followingCount = post.followingCount
  //             ..isLiked = post.isLiked
  //             ..isSaved = post.isSaved
  //             ..likesCount = post.likesCount
  //             ..commentsCount = post.commentsCount
  //             ..savesCount = post.savesCount
  //             ..shareCount = post.shareCount
  //             ..createdAt = post.createdAt ?? DateTime.now()
  //             ..updatedAt = post.updatedAt ?? DateTime.now();

  //       await isar.postEntitys.put(entity);
  //     }
  //   });
  // }

  void updatePostCommentsCount(String postId, int newCount) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(commentsCount: newCount);
    }
  }

  Future<void> toggleLike(Post post) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index == -1) return;

      _posts[index] = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
      );

      await _apiController.post('/toggleLike/${post.id}', {'userId': userId});
    } catch (_) {}
  }

  Future<void> toggleSave(Post post) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index == -1) return;

      _posts[index] = post.copyWith(
        isSaved: !post.isSaved,
        savesCount: post.isSaved ? post.savesCount - 1 : post.savesCount + 1,
      );

      await _apiController.post('/toggleSave/${post.id}', {'userId': userId});
    } catch (_) {}
  }

  Future<void> sharePost(Post post) async {
    try {
      final response = await _apiController.post('/sharePost/${post.id}', {});
      if (response['success'] == true) {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = post.copyWith(shareCount: response['shareCount']);
        }
      }
    } catch (_) {}
  }

  Future<void> loadMorePosts() async {
    if (!_hasMorePosts.value || _isLoadingMore.value) return;
    _currentPage.value++;
    await fetchPosts();
  }

  Future<void> refreshPosts() async {
    await fetchPosts(refresh: true);
  }

  void clearError() {
    _error.value = '';
  }
}
