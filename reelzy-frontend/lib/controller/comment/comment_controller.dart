import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorts_app/controller/api/api_controller.dart';
import 'package:shorts_app/controller/post/post_controller.dart';
import 'package:shorts_app/model/comment_model.dart';
import 'package:shorts_app/controller/comment/base_comments_controller.dart';

class CommentsController extends BaseCommentsController {
  final String postId;
  
  CommentsController({required this.postId});
  
  @override
  final TextEditingController commentController = TextEditingController();
  @override
  final ScrollController scrollController = ScrollController();
  
  final PostsController postsController = Get.find<PostsController>();
  
  @override
  final RxList<Comment> comments = <Comment>[].obs;
  @override
  final RxBool isLoading = false.obs;
  @override
  final RxBool isLoadingMore = false.obs;
  @override
  final RxBool isTyping = false.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMoreComments = true.obs;

  final ApiController apiController = Get.find<ApiController>();
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
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      if (hasMoreComments.value && !isLoadingMore.value) {
        loadMoreComments();
      }
    }
  }

  Future<void> fetchComments({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 1;
        hasMoreComments.value = true;
      }

      if (currentPage.value == 1) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      final response = await apiController.get(
        '/getPostComments/$postId?page=${currentPage.value}&limit=20'
      );

      if (response['success'] == true) {
        final List<dynamic> commentsData = response['data'] ?? [];
        final List<Comment> newComments = commentsData
            .map((json) => Comment.fromJson(json))
            .toList();

        if (refresh || currentPage.value == 1) {
          comments.value = newComments;
        } else {
          comments.addAll(newComments);
        }
        print('Fetched ${newComments.length} comments for post $postId');

        hasMoreComments.value = newComments.length >= 20;
      }

    } catch (e) {
      print('fetchComments error: $e');
      Get.snackbar('Error', 'Failed to load comments');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreComments() async {
    if (!hasMoreComments.value || isLoadingMore.value) return;
    currentPage.value++;
    await fetchComments();
  }

  @override
  Future<void> addComment() async {
    if (commentController.text.trim().isEmpty) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'Please sign in to comment');
        return;
      }

      final commentText = commentController.text.trim();
      commentController.clear();

      final tempComment = Comment(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.uid,
        username: currentUser.displayName ?? 'You',
        content: commentText,
        profilePic: currentUser.photoURL!,
        timeAgo: DateTime.now(),
      );

      comments.insert(0, tempComment);

      final response = await apiController.post(
        '/addPostComment/$postId',
        {
          'userId': currentUser.uid,
          'username': currentUser.displayName ?? 'Anonymous',
          'content': commentText,
          'profilePic': currentUser.photoURL!,
        },
      );

      if (response['success'] == true) {
        final newComment = Comment.fromJson(response['data']);
        final tempIndex = comments.indexWhere((c) => c.id == tempComment.id);
        if (tempIndex != -1) {
          comments[tempIndex] = newComment;
        }

        postsController.updatePostCommentsCount(postId, response['data']['commentsCount']);
        print('Comment added: ${newComment.content}');

        if (scrollController.hasClients) {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      } else {
        comments.removeWhere((c) => c.id == tempComment.id);
        Get.snackbar('Error', response['error'] ?? 'Failed to add comment');
      }
    } catch (e) {
      print('addComment error: $e');
      Get.snackbar('Error', 'Failed to add comment');
    }
  }
  
  @override
  Future<void> toggleLike(Comment comment) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar('Error', 'Please sign in to like');
        return;
      }

      comment.isLiked.value = !comment.isLiked.value;
      comment.isLiked.value ? comment.likes.value++ : comment.likes.value--;

      print('comment id: ${comment.id}, postId: $postId');

      final response = await apiController.post(
        '/toggleCommentLike/$postId/${comment.id}',
        {'userId': currentUser.uid},
      );

      if (response['success'] == true) {
        comment.likes.value = response['likesCount'];
        comment.isLiked.value = response['liked'];
      }
    } catch (e) {
      print('toggleLike error: $e');
      comment.isLiked.value = !comment.isLiked.value;
      comment.isLiked.value ? comment.likes.value++ : comment.likes.value--;
      Get.snackbar('Error', 'Failed to like comment');
    }
  }

  @override
  void startReply(Comment comment) {
    replyingTo.value = comment;
    commentController.text = '@${comment.username} ';
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