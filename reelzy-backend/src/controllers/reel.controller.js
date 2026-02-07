const Reel = require('../models/reels');
const Media = require('../models/Media');
const reelActivity = require('../models/ReelActivitySchema')

const ensureReelFromMedia = async (mediaId) => {

  const media = await Media.findById(mediaId);

  if (!media) {
    return null;
  }



  if (media.mediaType !== 'video') {
    return null;
  }

  let reel = await Reel.findOne({ videoUrl: media.url });


  if (reel) {
    console.log('Reel already exists');
    console.log(' reel._id:', reel._id.toString());
    return reel;
  }




  reel = await Reel.create({
    userId: media.userId,
    description: media.caption || '',
    hashtags: media.hashtags || [],
    videoUrl: media.url,
    musicTitle: 'Original Sound',
    thumbnail: media.thumbnail
  });

  console.log('new reel._id:', reel._id.toString());

  return reel;
};


const toggleReelLike = async (req, res) => {
  const { reelId } = req.params;
  const { userId } = req.body;

  try {
    const reel = await ensureReelFromMedia(reelId);
    if (!reel) return res.status(404).json({ success: false });

    let reelAct = await reelActivity.findOne({ userId });

    if (!reelAct) {
      reelAct = new reelActivity({
        userId,
        likedReels: [],
        savedReels: [],
      });
    }

    const index = reelAct.likedReels.findIndex(
      id => id.toString() === reel._id.toString()
    );

    if (index > -1) {
      reelAct.likedReels.splice(index, 1);
      reel.likeCount = Math.max(0, reel.likeCount - 1);
    } else {
      reelAct.likedReels.push(reel._id);
      reel.likeCount += 1;
    }

    await reelAct.save(); 
    await reel.save();

    return res.json({
      success: true,
      liked: index === -1,
      likesCount: reel.likeCount,
    });
  } catch (e) {
    console.error('toggleReelLike ERROR:', e);
    return res.status(500).json({ success: false });
  }
};


const toggleReelSave = async (req, res) => {
  const { reelId } = req.params;
  const { userId } = req.body;

  try {
    const reel = await ensureReelFromMedia(reelId);
    if (!reel) return res.status(404).json({ success: false });

    let reelAct = await reelActivity.findOne({ userId });

    if (!reelAct) {
      reelAct = await reelActivity.create({
        userId,
        likedReels: [],
        savedReels: []
      });
    }

     const index = reelAct.savedReels.findIndex(
      id => id.toString() === reel._id.toString()
    );

    if (index > -1) {
      reelAct.savedReels.splice(index, 1);
      reel.saveCount = Math.max(0, reel.saveCount - 1);
    }
    else {
      reelAct.savedReels.push(reel._id);
      reel.saveCount += 1;

    }

    await reelAct.save();
    await reel.save();

    res.json({
      success: true,
      saved: index === -1,
      savesCount: reel.saveCount,
    });
  } catch {
    res.status(500).json({ success: false });
  }
};

const shareReel = async (req, res) => {
  const { reelId } = req.params;

  try {
    const reel = await ensureReelFromMedia(reelId);
    if (!reel) return res.status(404).json({ success: false });

    reel.shareCount += 1;
    await reel.save();

    res.json({
      success: true,
      shareCount: reel.shareCount,
    });
  } catch {
    res.status(500).json({ success: false });
  }
};


const getLikedReels = async (req, res) => {
  const { userId } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  try {
    const reelAct = await reelActivity.findOne({ userId }).populate({
      path: 'likedReels',
      options: {
        skip: skip,
        limit: limit
      }
    })

    if (!reelAct || reelAct.likedReels.length === 0) {
      return res.json({
        success: true,
        likedReels: [],
        page,
        totalPages: 0,
        total: 0
      });
    }


    res.json({
      success: true,
      likedReels: reelAct.likedReels.map(r => ({
        id: r._id,
        url: r.videoUrl,
        thumbnail: r.thumbnail,
        description: r.description,
        hashtags: r.hashtags,
        likeCount: r.likeCount,
        saveCount: r.saveCount,
        shareCount: r.shareCount,
      }))
    });

  } catch (err) {
    res.status(500).json({ success: false });
  }
};


const getSavedReels = async (req, res) => {
  const { userId } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const skip = (page - 1) * limit;

  try {
    const reelAct = await reelActivity.findOne({ userId }).populate({
      path: 'savedReels',
      options: {
        skip: skip,
        limit: limit
      }
    })

    if (!reelAct || reelAct.savedReels.length === 0) {
      return res.json({
        success: true,
        savedReels: [],
        page,
        totalPages: 0,
        total: 0
      });
    }


    res.json({
      success: true,
      savedReels: reelAct.savedReels.map(r => ({
        id: r._id,
        url: r.videoUrl,
        thumbnail: r.thumbnail,
        description: r.description,
        hashtags: r.hashtags,
        likeCount: r.likeCount,
        saveCount: r.saveCount,
        shareCount: r.shareCount,
      }))
    });

  } catch (err) {
    res.status(500).json({ success: false });
  }
};

const getMyVideos = async (req, res) => {
  const { userId } = req.params;

  try {
    const videos = await Media.find({
      userId,
      mediaType: 'video',
    })
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      videos: videos.map(v => ({
        id: v._id,
        url: v.url,
        thumbnail: v.thumbnail || null,
        createdAt: v.createdAt,
      })),
    });
  } catch (err) {
    console.error('getMyVideos error:', err);
    res.status(500).json({ success: false });
  }
};


const addReelComment = async (req, res) => {
  const { reelId } = req.params;
  const { userId, username, content, profilePic } = req.body;

  if (!userId || !username || !content?.trim()) {
    return res.status(400).json({
      success: false,
      error: 'userId, username, and content are required',
    });
  }

  try {
    const reel = await ensureReelFromMedia(reelId);
    if (!reel) {
      return res.status(404).json({ success: false, error: 'Reel not found' });
    }

    const newComment = {
      userId,
      username,
      content: content.trim(),
      profilePic: profilePic || '',
      timeAgo: new Date(),
      likes: [],
      replies: [],
    };

    reel.comments.unshift(newComment);
    await reel.save();

    return res.status(201).json({
      success: true,
      data: reel.comments[0],
      commentsCount: reel.comments.length,
    });

  } catch (err) {
    console.error('addReelComment error:', err);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};


const getReelComments = async (req, res) => {
  const { reelId } = req.params;
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;

  try {
    const reel = await ensureReelFromMedia(reelId);
    if (!reel) {
      return res.status(404).json({ success: false, error: 'Reel not found' });
    }

    const sorted = [...reel.comments].sort(
      (a, b) => new Date(b.timeAgo) - new Date(a.timeAgo)
    );

    const start = (page - 1) * limit;
    const paginated = sorted.slice(start, start + limit);

    res.json({
      success: true,
      data: paginated,
      total: reel.comments.length,
      currentPage: page,
      hasMore: start + limit < reel.comments.length,
    });

  } catch (err) {
    console.error('getReelComments error:', err);
    res.status(500).json({ success: false });
  }
};


const toggleReelCommentLike = async (req, res) => {
  const { reelId, commentId } = req.params;
  const { userId } = req.body;

  try {
    const reel = await ensureReelFromMedia(reelId);
    if (!reel) return res.status(404).json({ success: false });

    const comment = reel.comments.id(commentId);
    if (!comment) {
      return res.status(404).json({ success: false, error: 'Comment not found' });
    }

    const index = comment.likes.indexOf(userId);

    if (index > -1) {
      comment.likes.splice(index, 1);
    } else {
      comment.likes.push(userId);
    }

    await reel.save();

    res.json({
      success: true,
      liked: index === -1,
      likesCount: comment.likes.length,
    });

  } catch (err) {
    console.error('toggleReelCommentLike error:', err);
    res.status(500).json({ success: false });
  }
};


const addReelCommentReply = async (req, res) => {
  const { reelId, commentId } = req.params;
  const { userId, username, content, profilePic } = req.body;

  try {
    const reel = await ensureReelFromMedia(reelId);
    if (!reel) return res.status(404).json({ success: false });

    const comment = reel.comments.id(commentId);
    if (!comment) return res.status(404).json({ success: false });

    const reply = {
      userId,
      username,
      content: content.trim(),
      profilePic: profilePic || '',
      timeAgo: new Date(),
    };

    comment.replies.push(reply);
    await reel.save();

    res.json({
      success: true,
      data: reply,
      repliesCount: comment.replies.length,
    });

  } catch (err) {
    console.error('addReelCommentReply error:', err);
    res.status(500).json({ success: false });
  }
};


const deleteReelComment = async (req, res) => {
  const { reelId, commentId } = req.params;
  const { userId } = req.body;

  try {
    const reel = await ensureReelFromMedia(reelId);
    if (!reel) return res.status(404).json({ success: false });

    const comment = reel.comments.id(commentId);
    if (!comment) return res.status(404).json({ success: false });

    if (comment.userId !== userId && reel.userId !== userId) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }

    comment.deleteOne();
    await reel.save();

    res.json({
      success: true,
      commentsCount: reel.comments.length,
    });

  } catch (err) {
    console.error('deleteReelComment error:', err);
    res.status(500).json({ success: false });
  }
};


module.exports = {
  toggleReelLike,
  toggleReelSave,
  shareReel,
  getLikedReels,
  getSavedReels,
  getMyVideos,

  addReelComment,
  getReelComments,
  toggleReelCommentLike,
  addReelCommentReply,
  deleteReelComment,
};
