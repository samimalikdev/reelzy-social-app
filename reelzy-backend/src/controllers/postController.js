const Post = require('../models/post');
const User = require('../models/User');
const { convertToCDN } = require('../services/cdn.service');

const addPost = async (req, res) => {

  const {
    userId,
    username,
    content,
    location,
    mediaUrl,
    mediaType,
    linkUrl,
    linkTitle
  } = req.body;



  if (!userId || !username || !content) {
    return res.status(400).json({
      success: false,
      error: 'userId, username, and content are required'
    });
  }

  try {
    let user = await User.findOne({ userId });

    if (!user) {
      user = new User({
        userId,
        username: username,
        email: '',
        profilePic: '',
        bio: '',
        followers: [],
        following: []
      });
      await user.save();
    } 

    const hashtags = content.match(/#\w+/g) || [];
    if (hashtags.length > 0) {
    }

    const linkPreview = {};
    if (linkUrl) {
      linkPreview.url = linkUrl;
      linkPreview.title = linkTitle || linkUrl;
    }

    const newPost = new Post({
      userId,
      username,
      content: content.trim(),
      location: location || '',
      mediaUrl: convertToCDN(mediaUrl) || '',
      mediaType: mediaType || 'none',
      linkPreview,
      hashtags: hashtags.map(tag => tag.substring(1)), 
    });

    const savedPost = await newPost.save();


    res.status(201).json({
      success: true,
      message: 'Post created successfully',
      data: {
        id: savedPost._id,
        userId: savedPost.userId,
        username: savedPost.username,
        content: savedPost.content,
        location: savedPost.location,
        mediaUrl: savedPost.mediaUrl,
        mediaType: savedPost.mediaType,
        linkPreview: savedPost.linkPreview,
        hashtags: savedPost.hashtags,
        likes: savedPost.likes,
        comments: savedPost.comments,
        createdAt: savedPost.createdAt
      }
    });


  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

const getAllPosts = async (req, res) => {
  try {
    const { page = 1, limit = 10, userId } = req.query;
    const skip = (page - 1) * limit;

    const posts = await Post.find({})
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const totalPosts = await Post.countDocuments({});

    const userIds = [...new Set(posts.map(e => e.userId))];

    const users = await User.find({ userId: { $in: userIds } }).lean();
    const userMap = {};

    users.forEach(user => {
      userMap[user.userId] = {
        username: user.username,      
        profilePic: user.profilePic,
        bio: user.bio,
        followersCount: user.followers.length,
        followingCount: user.following.length,
      };
    });

    const postsWithUserData = posts.map(post => ({
      ...post,

      user: {
        userId: post.userId,
        username: userMap[post.userId]?.username || 'Unknown',
        profilePic: userMap[post.userId]?.profilePic || '',
        bio: userMap[post.userId]?.bio || '',
        followersCount: userMap[post.userId]?.followersCount || 0,
        followingCount: userMap[post.userId]?.followingCount || 0,
      },

      isLiked: userId ? post.likes.includes(userId) : false,
      isSaved: userId ? post.saves.includes(userId) : false,
      likesCount: post.likes.length,
      savesCount: post.saves.length,
      commentsCount: post.comments.length,
      userBio: userMap[post.userId]?.bio || '',
    }));

    res.status(200).json({
      success: true,
      currentPage: parseInt(page),
      totalPages: Math.ceil(totalPosts / limit),
      totalPosts,
      length: postsWithUserData.length,
      data: postsWithUserData
    });

  } catch (err) {
    console.error('getAllPosts error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

const getPostsByUserId = async (req, res) => {
  const { userId } = req.params;

  if (!userId) {
    return res.status(400).json({
      success: false,
      error: 'userId is required'
    });
  }

  try {
    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    const posts = await Post.find({ userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const totalPosts = await Post.countDocuments({ userId });

    res.status(200).json({
      success: true,
      userId,
      currentPage: parseInt(page),
      totalPages: Math.ceil(totalPosts / limit),
      totalPosts,
      length: posts.length,
      data: posts
    });

  } catch (err) {
    console.error('getPostsByUserId error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

const toggleLike = async (req, res) => {
  const { postId } = req.params;
  const { userId } = req.body;



  

  try {
    const user = await User.findOne({userId});
    const post = await Post.findById(postId);


      if (!post || !user) {
    return res.status(404).json({ success: false });
  }

    const likedIndex = post.likes.indexOf(userId);

    if (likedIndex > -1) {
      post.likes.splice(likedIndex, 1);
      user.likedVideos.pull(postId)
      await post.save();
      await user.save();

      console.log('Unlike post: ', postId, 'by user:', userId);

      return res.status(200).json({
        success: true,
        message: 'Post unliked',
        liked: false,
        likesCount: post.likes.length
      });
    } else {
      post.likes.push(userId);
      user.likedVideos.push(postId);
      await post.save();
      await user.save();

      console.log('Like post: ', postId, 'by user:', userId);

      return res.status(200).json({
        success: true,
        message: 'Post liked',
        liked: true,
        likesCount: post.likes.length
      });
    }
  } catch (err) {
    console.error('toggleLike error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};


const toggleSave = async (req, res) => {
  const { postId } = req.params;
  const { userId } = req.body;

  try {
    const user = await User.findOne({ userId });
    const post = await Post.findById(postId);

    if (!post || !user) {
      return res.status(404).json({ success: false });
    }

    const savedIndex = post.saves.indexOf(userId);

    if (savedIndex > -1) {
      post.saves.splice(savedIndex, 1);
      user.savedVideos.pull(postId);
      await post.save();
      await user.save();

      return res.status(200).json({
        success: true,
        saved: false,
        savesCount: post.saves.length
      });
    } else {
      post.saves.push(userId);
      user.savedVideos.push(postId);
      await post.save();
      await user.save();

      return res.status(200).json({
        success: true,
        saved: true,
        savesCount: post.saves.length
      });
    }
  } catch (err) {
    res.status(500).json({ success: false });
  }
};


const sharePost = async (req, res) => {
  const { postId } = req.params;

  try {
    const post = await Post.findById(postId);

    if (!post) {
      return res.status(404).json({
        success: false,
        error: 'Post not found'
      });
    }

    post.shareCount += 1;
    await post.save();

    res.status(200).json({
      success: true,
      message: 'Post shared',
      shareCount: post.shareCount
    });
  } catch (err) {
    console.error('sharePost error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

module.exports = {
  addPost,
  getAllPosts,
  getPostsByUserId,
  toggleLike,
  toggleSave,
  sharePost
};