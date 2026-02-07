const mongoose = require('mongoose');
const CommentSchema = require('./comments');

const reelSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true,
  },
  description: {
    type: String,
    default: '',
  },
  hashtags: {
    type: [String],
    default: [],
  },
  imageUrl: {
    type: String,
    default: '',
  },
  videoUrl: {
    type: String,
    required: true,
  },
  saveCount: {
    type: Number,
    default: 0,
  },
  comments: [CommentSchema],
  likeCount: {
    type: Number,
    default: 0,
  },
  shareCount: {
    type: Number,
    default: 0,
  },
  commentsCount: {
    type: Number,
    default: 0,
  },
  isVerified: {
    type: Boolean,
    default: false,
  },
  musicTitle: {
    type: String,
    default: '',
  },
  thumbnail: {
    type: String,
    default: '',
  }
}, { 
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

reelSchema.pre('save', function(next) {
  if (this.isModified('comments')) {
    this.commentsCount = this.comments.length;
  }
  next();
});

reelSchema.index({ userId: 1, createdAt: -1 });
reelSchema.index({ videoUrl: 1 });
reelSchema.index({ 'comments._id': 1 });

module.exports = mongoose.model('Reel', reelSchema);