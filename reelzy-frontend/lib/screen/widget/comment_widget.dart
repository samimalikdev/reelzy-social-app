import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shorts_app/controller/comment/base_comments_controller.dart';
import 'package:shorts_app/model/comment_model.dart';
import 'package:shorts_app/service/authentication.dart';

class CommentsSheet<T extends BaseCommentsController> extends StatelessWidget {
  final String id;
  final T controller;

  const CommentsSheet({
    super.key,
    required this.id,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {

    return GetBuilder<T>(
      init: controller,
      tag: id,
      builder: (controller) {
        return Container(
          height: Get.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBF9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildCommentsList(controller),
              ),
              _buildAddCommentSection(controller),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D7A4F), Color(0xFF3B9A65)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
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
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.comment_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Comments',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(BaseCommentsController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.comments.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2D7A4F),
          ),
        );
      }

      if (controller.comments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D7A4F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.comment_outlined,
                  size: 64,
                  color: const Color(0xFF2D7A4F).withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No comments yet',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to comment!',
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

      return ListView.separated(
        controller: controller.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: controller.comments.length + (controller.isLoadingMore.value ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == controller.comments.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Color(0xFF2D7A4F),
                ),
              ),
            );
          }

          final comment = controller.comments[index];
          return CommentWidget(
            comment: comment,
            controller: controller,
          );
        },
      );
    });
  }

  Widget _buildAddCommentSection(BaseCommentsController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          if (controller.replyingTo.value != null) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D7A4F).withOpacity(0.1),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFF2D7A4F).withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D7A4F).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.reply,
                      color: Color(0xFF2D7A4F),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6B7280),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '@${controller.replyingTo.value!.username}',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B7280).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF6B7280),
                        size: 16,
                      ),
                    ),
                    onPressed: controller.cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: const Color(0xFF2D7A4F).withOpacity(0.1),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
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
                  padding: const EdgeInsets.all(2),
                  child:  CircleAvatar(
                    backgroundImage: NetworkImage(Get.find<AuthenticationService>().photoURL ?? 'https://i.pravatar.cc/150?img=3'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBF9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2D7A4F).withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: controller.commentController,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF9FA5AA),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => controller.addComment(),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Obx(() => GestureDetector(
                      onTap: controller.addComment,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: controller.isTyping.value
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF2D7A4F), Color(0xFF3B9A65)],
                                )
                              : LinearGradient(
                                  colors: [
                                    const Color(0xFF9FA5AA).withOpacity(0.3),
                                    const Color(0xFF9FA5AA).withOpacity(0.2),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: controller.isTyping.value
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2D7A4F).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: controller.isTyping.value
                              ? Colors.white
                              : const Color(0xFF9FA5AA),
                          size: 20,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CommentWidget extends StatelessWidget {
  final Comment comment;
  final BaseCommentsController controller;

  const CommentWidget({
    super.key,
    required this.comment,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfilePicture(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfo(),
                const SizedBox(height: 8),
                _buildCommentText(),
                const SizedBox(height: 12),
                _buildActionRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      width: 44,
      height: 44,
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
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        backgroundImage: NetworkImage(comment.profilePic ?? 'https://i.pravatar.cc/150?img=3'),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        Text(
          comment.username,
          style: GoogleFonts.inter(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.3,
          ),
        ),
        if (comment.isVerified) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D7A4F), Color(0xFF3B9A65)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 10,
            ),
          ),
        ],
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2D7A4F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            comment.formattedTime,
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentText() {
    return Text(
      comment.content,
      style: GoogleFonts.inter(
        color: const Color(0xFF1A1A1A),
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => controller.toggleLike(comment),
          child: Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: comment.isLiked.value
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFFF8FBF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: comment.isLiked.value
                        ? Colors.red.withOpacity(0.2)
                        : const Color(0xFF2D7A4F).withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      comment.isLiked.value ? Icons.favorite : Icons.favorite_border,
                      color: comment.isLiked.value
                          ? Colors.red
                          : const Color(0xFF6B7280),
                      size: 16,
                    ),
                    if (comment.likes.value > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        comment.likes.value.toString(),
                        style: GoogleFonts.inter(
                          color: comment.isLiked.value
                              ? Colors.red
                              : const Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
        ),

        const SizedBox(width: 10),

        GestureDetector(
          onTap: () => controller.startReply(comment),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2D7A4F).withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.reply_rounded,
                  color: Color(0xFF6B7280),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Reply',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}