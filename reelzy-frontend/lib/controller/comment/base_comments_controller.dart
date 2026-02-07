import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorts_app/model/comment_model.dart';

abstract class BaseCommentsController extends GetxController {
  TextEditingController get commentController;
  ScrollController get scrollController;
  RxList<Comment> get comments;
  RxBool get isLoading;
  RxBool get isLoadingMore;
  RxBool get isTyping;
  Rx<Comment?> get replyingTo;
  
  Future<void> addComment();
  Future<void> toggleLike(Comment comment);
  void startReply(Comment comment);
  void cancelReply();
}