const mongoose = require('mongoose');

const CommentSchema = new mongoose.Schema({ 
  userId: {
    type: String,
  },
  username: {
    type: String,
  },
  content: {
    type: String,
  },
  profilePic: {
    type: String,
    default: ''
  },
  timeAgo: {
    type: Date,
    default: Date.now
  },
  likes: { 
    type: [String], 
    default: [] 
  }, 
  replies: [{  
    userId: String,
    username: String,
    content: String,
    profilePic: String,
    timeAgo: {
      type: Date,
      default: Date.now
    }
  }]
}, { 
  timestamps: true,
  _id: true
});

module.exports = CommentSchema;