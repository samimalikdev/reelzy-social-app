import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/model/comment_model.dart';
import 'package:shorts_app/controller/comment/base_comments_controller.dart';

class ReelCommentsController extends BaseCommentsController {
  final String reelId;

  ReelCommentsController({required this.reelId});

  @override
  final TextEditingController commentController = TextEditingController();
  @override
  final ScrollController scrollController = ScrollController();

  final ApiController apiController = Get.find<ApiController>();

  @override
  final RxList<Comment> comments = <Comment>[].obs;
  @override
  final RxBool isLoading = false.obs;
  @override
  final RxBool isLoadingMore = false.obs;
  @override
  final RxBool isTyping = false.obs;

  final RxInt currentPage = 1.obs;
  final RxBool hasMore = true.obs;

  @override
  final Rx<Comment?> replyingTo = Rx<Comment?>(null);

  @override
  void onInit() {
    super.onInit();

    commentController.addListener(() {
      isTyping.value = commentController.text.trim().isNotEmpty;
    });

    scrollController.addListener(_onScroll);
    fetchComments();
  }

  @override
  void onClose() {
    commentController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      if (hasMore.value && !isLoadingMore.value) {
        loadMore();
      }
    }
  }

  Future<void> fetchComments({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        hasMore.value = true;
      }

      currentPage.value == 1
          ? isLoading.value = true
          : isLoadingMore.value = true;

      final res = await apiController.get(
        '/reel/$reelId/comments?page=${currentPage.value}&limit=20',
      );

      if (res['success'] == true) {
        final List<Comment> newComments =
            (res['data'] as List).map((e) => Comment.fromJson(e)).toList();

        refresh || currentPage.value == 1
            ? comments.assignAll(newComments)
            : comments.addAll(newComments);

        hasMore.value = newComments.length == 20;
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value) return;
    currentPage.value++;
    await fetchComments();
  }

  @override
  Future<void> addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || commentController.text.trim().isEmpty) return;

    final text = commentController.text.trim();
    commentController.clear();

    final temp = Comment(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      username: user.displayName ?? 'You',
      content: text,
      profilePic: user.photoURL ?? 'https://i.pravatar.cc/150?img=3',
      timeAgo: DateTime.now(),
    );

    comments.insert(0, temp);

    try {
      final res = await apiController.post(
        '/reel/$reelId/comment',
        {
          'userId': user.uid,
          'username': user.displayName ?? 'User',
          'content': text,
          'profilePic': user.photoURL ?? 'https://i.pravatar.cc/150?img=3',
        },
      );

      final index = comments.indexWhere((c) => c.id == temp.id);
      if (index != -1) {
        comments[index] = Comment.fromJson(res['data']);
      }
    } catch (_) {
      comments.remove(temp);
    }
  }

  @override
  Future<void> toggleLike(Comment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wasLiked = comment.isLiked.value;
    comment.isLiked.value = !wasLiked;
    comment.likes.value += wasLiked ? -1 : 1;

    try {
      final res = await apiController.post(
        '/reel/$reelId/comment/${comment.id}/like',
        {'userId': user.uid},
      );

      comment.isLiked.value = res['liked'];
      comment.likes.value = res['likesCount'];
    } catch (_) {
      comment.isLiked.value = wasLiked;
      comment.likes.value += wasLiked ? 1 : -1;
    }
  }

  @override
  void startReply(Comment c) {
    replyingTo.value = c;
    commentController.text = '@${c.username} ';
    commentController.selection = TextSelection.fromPosition(
      TextPosition(offset: commentController.text.length),
    );
  }

  @override
  void cancelReply() {
    replyingTo.value = null;
    commentController.clear();
  }
}