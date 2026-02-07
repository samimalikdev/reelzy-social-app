const mongoose = require('mongoose');
const CommentSchema = require('./comments')


const postSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  username: { type: String, required: true },
  content: { type: String, required: true },
  location: { type: String, default: '' },
  mediaUrl: { type: String, default: '' },
  mediaType: { type: String, enum: ['none', 'image', 'video'], default: 'none' },
  linkPreview: {
    url: { type: String, default: '' },
    title: { type: String, default: '' }
  },
  hashtags: [{ type: String }],
  
  likes: { type: [String], default: [] },   
  saves: { type: [String], default: [] },
  shares: { type: [String], default: [] },

  comments: [CommentSchema],
  
  
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Post', postSchema);