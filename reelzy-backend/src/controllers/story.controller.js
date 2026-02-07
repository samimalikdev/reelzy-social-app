const uploadToS3 = require('../utils/uploadToS3');
const Story = require('../models/story');
const User = require('../models/User'); 

const uploadStory = async (req, res) => {
  try {
    
    const { url } = await uploadToS3(req, res);


    const { userId, mediaType } = req.body;

    if (!userId || !mediaType) {
      return res.status(400).json({
        success: false,
        error: 'userId & mediaType required',
      });
    }

    const user = await User.findOne({ userId });
    
    const story = await Story.create({
      userId,
      mediaUrl: url,
      mediaType,
      username: user?.username || 'Anonymous',
      profilePic: user?.profilePic || '',
    });


    res.json({
      success: true,
      message: 'Story uploaded successfully',
      story,
    });

  } catch (err) {
    console.error('uploadStory error:', err);
    
    if (!res.headersSent) {
      res.status(err.status || 500).json({
        success: false,
        error: err.message || 'Server error',
      });
    }
  }
};

const getStoriesFeed = async (req, res) => {
  const { userId } = req.params;

  try {

    const user = await User.findOne({ userId });

    if (!user) {
      return res.status(404).json({ 
        success: false,
        error: 'User not found'
      });
    }

    const allowedUsers = [...(user.following || []), userId];

    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const stories = await Story.find({
      userId: { $in: allowedUsers },
      createdAt: { $gte: twentyFourHoursAgo }
    }).sort({ createdAt: -1 });


    const storiesWithUserInfo = await Promise.all(
      stories.map(async (story) => {
        if (!story.username || !story.profilePic) {
          const storyUser = await User.findOne({ userId: story.userId });
          return {
            ...story.toObject(),
            username: storyUser?.username || story.username || 'Anonymous',
            profilePic: storyUser?.profilePic || story.profilePic || '',
          };
        }
        return story.toObject();
      })
    );

    res.json({
      success: true,
      stories: storiesWithUserInfo
    });

  } catch (err) {
    console.error('getStoriesFeed error:', err);
    res.status(500).json({ 
      success: false,
      error: err.message || 'Server error'
    });
  }
};

module.exports = { uploadStory, getStoriesFeed };