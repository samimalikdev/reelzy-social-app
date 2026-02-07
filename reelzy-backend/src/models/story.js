const mongoose = require('mongoose');

const StorySchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true
  },

  mediaUrl: {
    type: String,
    required: true
  },

  mediaType: {
    type: String,
    enum: ['image', 'video'],
    required: true
  },

  createdAt: {
    type: Date,
    default: Date.now,
    expires: 60 * 60 * 24 
  }
});

module.exports = mongoose.model('Story', StorySchema);
