

const multer = require('multer');
const path = require('path');
const { upload } = require('../middleware/upload');
const Media = require('../models/Media');
const { convertToCDN } = require('../services/cdn.service');
const User = require('../models/User')
const Reel = require('../models/reels');
const reelActivity = require('../models/ReelActivitySchema');

const getAllMedia = async (req, res) => {
  const { type, page = 1, limit = 10, userId } = req.query; 

  try {
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const skip = (pageNum - 1) * limitNum;

    let filter = {};
    if (type === 'image') {
      filter.mimetype = { $regex: '^image/', $options: 'i' };
    } else if (type === 'video') {
      filter.$or = [
        { mimetype: { $regex: '^video/', $options: 'i' } },
        { mimetype: 'application/octet-stream' }
      ];
    }

    const totalCount = await Media.countDocuments(filter);
    const totalPages = Math.ceil(totalCount / limitNum);


    const mediaFiles = await Media.find(filter)
      .select('url mimetype size originalname uploadedAt metadata thumbnail userId')
      .sort({ uploadedAt: -1 })
      .skip(skip)
      .limit(limitNum)
      .lean();

    const userIds = [...new Set(mediaFiles.map(e => e.userId))];

    const users = await User.find({ userId: { $in: userIds } })
      .select('userId username profilePic')
      .lean();

    const userMap = {};
    users.forEach(e => {
      userMap[e.userId] = {
        username: e.username,
        profilePic: e.profilePic
      };
    });

    const videoUrls = mediaFiles
      .filter(item => {
        const ext = (item.originalname || '').split('.').pop().toLowerCase();
        const videoExts = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
        return (item.mimetype && item.mimetype.startsWith('video/')) || videoExts.includes(ext);
      })
      .map(item => convertToCDN(item.url));

    const reels = await Reel.find({ videoUrl: { $in: videoUrls } })
      .select('videoUrl likeCount saveCount shareCount commentsCount _id')
      .lean();

    const reelMap = {};
    reels.forEach(reel => {
      reelMap[reel.videoUrl] = {
        reelId: reel._id,
        likeCount: reel.likeCount || 0,
        saveCount: reel.saveCount || 0,
        shareCount: reel.shareCount || 0,
        commentsCount: reel.commentsCount || 0  
      };
    });

    let userLikedReels = [];
    let userSavedReels = [];
    
    if (userId) {
      const userActivity = await reelActivity.findOne({ userId }).lean();
      
      if (userActivity) {
        userLikedReels = userActivity.likedReels.map(id => id.toString());
        userSavedReels = userActivity.savedReels.map(id => id.toString());
      }
    }

    const formattedData = mediaFiles.map(item => {
      const ext = (item.originalname || '').split('.').pop().toLowerCase();
      const videoExts = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
      const isVideo = (item.mimetype && item.mimetype.startsWith('video/')) || 
                      videoExts.includes(ext);

      const cdnUrl = convertToCDN(item.url);
      const reelData = reelMap[cdnUrl] || { 
        reelId: null,
        likeCount: 0, 
        saveCount: 0, 
        shareCount: 0,
        commentsCount: 0
      };

      const isLiked = reelData.reelId ? userLikedReels.includes(reelData.reelId.toString()) : false;
      const isSaved = reelData.reelId ? userSavedReels.includes(reelData.reelId.toString()) : false;

      return {
        id: item._id,
        url: cdnUrl,
        type: isVideo ? 'video' : 'image',
        size: item.size,
        originalname: item.originalname,
        uploadedAt: item.uploadedAt,
        thumbnail: item.thumbnail,
        caption: item.metadata?.caption || '',
        hashtags: item.metadata?.hashtags || [],
        username: userMap[item.userId]?.username || '',
        profilePic: userMap[item.userId]?.profilePic || '',
        targetId: item.userId,
        reelId: reelData.reelId,
        likeCount: reelData.likeCount,
        saveCount: reelData.saveCount,
        shareCount: reelData.shareCount,
        commentCount: reelData.commentsCount,  
        isLiked: isLiked,
        isSaved: isSaved,
      };
    });

    const finalData = type
      ? formattedData.filter(item => item.type === type)
      : formattedData;

    res.status(200).json({
      success: true,
      data: finalData,
      pagination: {
        currentPage: pageNum,
        totalPages: totalPages,
        totalItems: totalCount,
        itemsPerPage: limitNum,
        hasNextPage: pageNum < totalPages,
        hasPrevPage: pageNum > 1
      }
    });

  } catch (err) {
    console.error('getAllMedia error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
      message: err.message
    });
  }
};



const getMediaById = async (req, res) => {
  const { userId, type } = req.query;

  if (!userId) {
    return res.status(400).json({
      success: false,
      error: 'userId is required'
    });
  }

  try {
    const filter = { userId };

    if (type === 'image') {
      filter.mimetype = { $regex: '^image/', $options: 'i' };
    } else if (type === 'video') {
      filter.mimetype = { $regex: '^video/', $options: 'i' };
    }

    const mediaFiles = await Media.find(filter)
      .select('url mimetype size originalname uploadedAt metadata')
      .sort({ uploadedAt: -1 })
      .lean();

    if (mediaFiles.length === 0) {
      const userExists = await Media.exists({ userId });
      if (!userExists) {
        return res.status(404).json({
          success: false,
          error: 'User not found'
        });
      }
    }

    const formattedData = mediaFiles.map(item => ({
      url: convertToCDN(item.url),
      type: item.mimetype.startsWith('video/') ? 'video' : 'image',
      size: item.size,
      originalname: item.originalname,
      uploadedAt: item.uploadedAt,
      caption: item.metadata?.caption || '',
      hashtags: item.metadata?.hashtags || []
    }));

    res.status(200).json({
      success: true,
      length: formattedData.length,
      userId,
      data: formattedData
    });
  } catch (err) {
    console.error('getMediaById error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};
const uploadMedia = async (req, res) => {
  console.log('Request headers:', req.headers);

  const uploadMultiple = upload.fields([
    { name: 'file', maxCount: 1 },
    { name: 'thumbnail', maxCount: 1 },
  ]);

  uploadMultiple(req, res, async (err) => {
    if (err instanceof multer.MulterError) {
      console.error('Multer error:', err);
      return res.status(400).json({
        success: false,
        error: err.message,
      });
    }

    if (err) {
      console.error('Upload error:', err);
      return res.status(400).json({
        success: false,
        error: err.message,
      });
    }

    const videoFile = req.files?.file?.[0];
    const thumbnailFile = req.files?.thumbnail?.[0];

    if (!videoFile) {
      return res.status(400).json({
        success: false,
        error: 'Video file is missing',
      });
    }

    if (!req.body.userId) {
      return res.status(400).json({
        success: false,
        error: 'userId is required',
      });
    }

    if (!req.body.caption) {
      return res.status(400).json({
        success: false,
        error: 'Caption is required',
      });
    }

    const extension = path.extname(videoFile.originalname).toLowerCase();
    const videoExts = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];

    const isVideo =
      videoFile.mimetype.startsWith('video/') ||
      videoExts.includes(extension);

    let hashtags = [];
    if (req.body.hashtags) {
      try {
        hashtags = JSON.parse(req.body.hashtags);
      } catch {
        hashtags = [];
      }
    }

    try {
      const mediaRecord = new Media({
        userId: req.body.userId,

        originalname: videoFile.originalname,
        filename: videoFile.key,
        url: convertToCDN(videoFile.location),
        key: videoFile.key,
        bucket: videoFile.bucket,
        mimetype: videoFile.mimetype,
        size: videoFile.size,
        mediaType: isVideo ? 'video' : 'image',
        extension: extension,

        thumbnail: thumbnailFile
          ? convertToCDN(thumbnailFile.location)
          : null,

        metadata: {
          caption: req.body.caption,
          hashtags: hashtags,
        },

        uploadedBy: req.ip,
      });

      const savedMedia = await mediaRecord.save();
      console.log('Media record saved:', savedMedia._id);

      return res.status(200).json({
        success: true,
        message: `${savedMedia.mediaType} uploaded successfully.`,
        file: {
          id: savedMedia._id,
          url: savedMedia.url,
          originalname: savedMedia.originalname,
          mimetype: savedMedia.mimetype,
          size: savedMedia.size,
          key: savedMedia.key,
          bucket: savedMedia.bucket,
          mediaType: savedMedia.mediaType,
          extension: savedMedia.extension,
          thumbnail: savedMedia.thumbnail ?? null,
          uploadedAt: savedMedia.uploadedAt,
          userId: savedMedia.userId,
        },
      });
    } catch (dbError) {
      console.error('Database error:', dbError);
      return res.status(500).json({
        success: false,
        error: 'File uploaded but failed to save to database',
      });
    }
  });
};


module.exports = {
  getAllMedia,
  getMediaById,
  uploadMedia,
};