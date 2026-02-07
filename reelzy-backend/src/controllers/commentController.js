const Post = require('../models/post');

const addPostComment = async (req, res) => {
  const { postId } = req.params;
  const { userId, username, content, profilePic } = req.body;

  if (!userId || !username || !content) {
    return res.status(400).json({
      success: false,
      error: 'userId, username, and content are required'
    });
  }

  try {
    const post = await Post.findById(postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        error: 'Post not found'
      });
    }

    if (!req.body.content || req.body.content.trim() === "") {
      return res.status(400).json({ success: false, error: "Comment cannot be empty" });
    }

    const newComment = {
      userId,
      username,
      content: content.trim(),
      profilePic: profilePic || '',
      timeAgo: new Date()
    };

    post.comments.push(newComment);
    await post.save();


    const addedComment = post.comments[post.comments.length - 1];

    res.status(201).json({
      success: true,
      message: 'Comment added successfully',
      data: {
        commentId: addedComment._id,
        userId: addedComment.userId,
        username: addedComment.username,
        content: addedComment.content,
        profilePic: addedComment.profilePic,
        timeAgo: addedComment.timeAgo,
        commentsCount: post.comments.length
      }
    });

  } catch (err) {
    console.error('addPostComment error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

const getPostComments = async (req, res) => {
  try {
    const { postId } = req.params;
    const { page = 1, limit = 20 } = req.query;

    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ success: false, message: "Post not found" });
    }

    const comments = Array.isArray(post.comments) ? post.comments : [];
    const sortedComments = comments.sort((a, b) => b.timeAgo - a.timeAgo);

    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + parseInt(limit);
    const paginatedComments = sortedComments.slice(startIndex, endIndex);



    return res.json({
      success: true,
      data: paginatedComments,
      total: comments.length,
      currentPage: parseInt(page),
      hasMore: endIndex < comments.length,
    });

  } catch (error) {
    console.error("getpostcomments error:", error);
    return res.status(500).json({ success: false, message: "Server Error" });
  }
};

const toggleCommentLike = async (req, res) => {
  const { postId, commentId } = req.params;
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({
      success: false,
      error: 'userId is required'
    });
  }

  try {
    const post = await Post.findById(postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        error: 'Post not found'
      });
    }

    const comment = post.comments.id(commentId);

    if (!comment) {
      return res.status(404).json({
        success: false,
        error: 'Comment not found'
      });
    }

    if (!comment.likes) {
      comment.likes = [];
    }

    const likedIndex = comment.likes.indexOf(userId);

    if (likedIndex > -1) {
      console.log('Unlike comment: ', commentId, 'by user:', userId);
      comment.likes.splice(likedIndex, 1);
    } else {
      console.log('Like comment: ', commentId, 'by user:', userId);
      comment.likes.push(userId);
    }

    await post.save();

    return res.status(200).json({
      success: true,
      liked: likedIndex === -1,
      likesCount: comment.likes.length
    });

  } catch (err) {
    console.error('toggleCommentLike error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

const addCommentReply = async (req, res) => {
  const { postId, commentId } = req.params;
  const { userId, username, content, profilePic } = req.body;

  if (!userId || !username || !content) {
    return res.status(400).json({
      success: false,
      error: 'userId, username, and content are required'
    });
  }

  try {
    const post = await Post.findById(postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        error: 'Post not found'
      });
    }

    const comment = post.comments.id(commentId);

    if (!comment) {
      return res.status(404).json({
        success: false,
        error: 'Comment not found'
      });
    }

    if (!comment.replies) {
      comment.replies = [];
    }

    const newReply = {
      userId,
      username,
      content: content.trim(),
      profilePic: profilePic || '',
      timeAgo: new Date()
    };

    comment.replies.push(newReply);
    await post.save();


    const addedReply = comment.replies[comment.replies.length - 1];

    res.status(201).json({
      success: true,
      message: 'Reply added successfully',
      data: addedReply,
      repliesCount: comment.replies.length
    });

  } catch (err) {
    console.error('addCommentReply error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

const deleteComment = async (req, res) => {
  const { postId, commentId } = req.params;
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({
      success: false,
      error: 'userId is required'
    });
  }

  try {
    const post = await Post.findById(postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        error: 'Post not found'
      });
    }

    const comment = post.comments.id(commentId);

    if (!comment) {
      return res.status(404).json({
        success: false,
        error: 'Comment not found'
      });
    }

    if (comment.userId !== userId && post.userId !== userId) {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized to delete this comment'
      });
    }

    comment.deleteOne();
    await post.save();

    res.status(200).json({
      success: true,
      message: 'Comment deleted successfully',
      commentsCount: post.comments.length
    });

  } catch (err) {
    console.error('deleteComment error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

module.exports = {
  addPostComment,
  getPostComments,
  toggleCommentLike,
  addCommentReply,
  deleteComment
};