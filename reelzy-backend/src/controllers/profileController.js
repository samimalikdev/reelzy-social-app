const { upload } = require('../middleware/upload');
const User = require('../models/User');
const { convertToCDN } = require('../services/cdn.service')
const uploadToS3 = require('../utils/uploadToS3');
const { getIO } = require('../socket/socket');

const toggleFollow = async (req, res) => {
  const { targetUserId } = req.params;
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({
      success: false,
      error: 'userId is required'
    });
  }

  if (userId === targetUserId) {
    return res.status(400).json({
      success: false,
      error: 'Cannot follow yourself'
    });
  }

  try {
    const currentUser = await User.findOne({ userId });
    const targetUser = await User.findOne({ userId: targetUserId });

    if (!targetUser) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    if (!currentUser) {
      const newUser = new User({
        userId,
        username: userId,
        followers: [],
        following: []
      });
      await newUser.save();
    }

    const user = currentUser || await User.findOne({ userId });

    const isFollowing = user.following.includes(targetUserId);

    if (isFollowing) {
      user.following = user.following.filter(id => id !== targetUserId);
      targetUser.followers = targetUser.followers.filter(id => id !== userId);
      console.log(`${userId} unfollowed ${targetUserId}`);
    } else {
      user.following.push(targetUserId);
      targetUser.followers.push(userId);
      console.log(`${userId} followed ${targetUserId}`);
    }

    await user.save();
    await targetUser.save();

    const io = getIO();
    const userRoom = `user-${userId}`;


    io.to(userRoom).emit('follow:update', {
      userId,
      followingCount: user.following.length,
    });


    res.status(200).json({
      success: true,
      isFollowing: !isFollowing,
      followersCount: targetUser.followers.length,
      followingCount: user.following.length,
      message: isFollowing ? 'Unfollowed successfully' : 'Followed successfully'
    });

  } catch (err) {
    console.error('toggleFollow error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

const saveFcmToken = async (req, res) => {
  const { userId, fcmToken } = req.body;

  if (!userId || !fcmToken) {
    return res.status(400).json({
      success: false,
      error: 'userId and fcmToken are required',
    });
  }

  try {
    const admin = require('../utils/firebase');
    
    try {
      await admin.messaging().send({
        token: fcmToken,
        data: { 
          type: 'token_validation',
          timestamp: Date.now().toString()
        },
        android: {
          priority: 'normal', 
        },
      });
      
      console.log('FCM token is valid');
    } catch (tokenError) {
      console.log('Invalid FCM token:', tokenError.code || tokenError.message);
      
      if (
        tokenError.code === 'messaging/registration-token-not-registered' ||
        tokenError.code === 'messaging/invalid-registration-token' ||
        tokenError.code === 'messaging/invalid-argument'
      ) {
        await User.findOneAndUpdate(
          { userId },
          { fcmToken: null },
          { new: true }
        );
        
        return res.status(200).json({
          success: false,
          message: 'Invalid FCM token - not saved',
          tokenValid: false,
          error: tokenError.code,
        });
      }
    }

    const user = await User.findOneAndUpdate(
      { userId },
      { fcmToken },
      { new: true, upsert: false }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    console.log(`Saved FCM token for user: ${userId}`);

    res.status(200).json({
      success: true,
      message: 'FCM token saved',
      tokenValid: true,
    });
  } catch (err) {
    console.error('saveFcmToken error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
};


const createUser = async (req, res) => {
  const { userId, username, email, profilePic } = req.body;

  try {

    const user = await User.findOne({ userId });

    if (!user) {
      newUser = new User({
        userId,
        email: email || '',
        username,
        profilePic: profilePic || '',
        bio: '',
        followers: [],
        following: []
      })

      await newUser.save();

      res.status(200).json({
        success: true,
        message: 'User synced successfully',
        data: {
          userId: newUser.userId,
          username: newUser.username
        }
      });
    }
  } catch (err) {
    console.error('syncUser error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
}



const getUserProfile = async (req, res) => {
  const { userId } = req.params;
  const { currentUserId } = req.query;

  try {
    const user = await User.findOne({ userId }).lean();

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const response = {
      followersCount: user.followers.length,
      followingCount: user.following.length,
      isFollowing: currentUserId ? user.followers.includes(currentUserId) : false,
      username: user.username,
      profilePic: user.profilePic
    };

    res.status(200).json({
      success: true,
      data: response
    });

  } catch (err) {
    console.error('getUserProfile error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
};

const uploadProfileToS3 = async (req, res) => {
  try {

    const { url } = await uploadToS3(req, res);

    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'userId is required',
      });
    }


    const user = await User.findOneAndUpdate(
      { userId },
      { profilePic: convertToCDN(url) },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    res.json({
      success: true,
      message: 'Profile picture updated',
      url,
    });

  } catch (err) {
    console.error('uploadProfile error:', err);
    res.status(err.status || 500).json({
      success: false,
      error: err.message || 'Server error',
    });
  }
};




const updateProfile = async (req, res) => {
  const { userId } = req.params;
  const { username, email, profilePic } = req.body;

  try {

    const user = await User.findOne({ userId });

    if (!user) {
      return res.status(404).json({
        success: false,
        error: "User not found",
      });
    }

    let isUpdted = false;

    if (username !== undefined && username !== user.username) {
      user.username = username;
      isUpdted = true;
    }

    if (email !== undefined && email !== user.email) {
      user.email = email;
      isUpdted = true;
    }

    if (profilePic !== undefined && profilePic !== user.profilePic) {
      user.profilePic = profilePic;
      isUpdted = true;
    }

    if (!isUpdted) {
      return res.status(400).json({
        success: false,
        error: "No changes updated",
      });
    }

    await user.save();

    res.status(200).json({
      success: true,
      message: "Profile updated successfully",
      data: user,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
}


const getAllUsers = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 15,
      search = '',
      excludeUserId
    } = req.query;

    const skip = (page - 1) * limit;

    const query = {};

    if (search) {
      query.$or = [
        { username: { $regex: search, $options: 'i' } },
        { userId: { $regex: search, $options: 'i' } },
      ];
    }

    if (excludeUserId) {
      query.userId = { $ne: excludeUserId };
    }

    const users = await User.find(query)
      .select('userId username profilePic')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit))
      .lean();

    const total = await User.countDocuments(query);

    res.status(200).json({
      success: true,
      page: Number(page),
      limit: Number(limit),
      total,
      hasMore: skip + users.length < total,
      users: users.map(u => ({
        userId: u.userId,
        username: u.username,
        profilePic: u.profilePic,
      })),
    });

  } catch (err) {
    console.error('getAllUsers error:', err);
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
};


module.exports = {
  toggleFollow,
  getUserProfile,
  createUser,
  updateProfile,
  uploadProfileToS3,
  saveFcmToken,
  getAllUsers
};
