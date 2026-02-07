const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  username: { type: String, required: true },
  email: { type: String },
  profilePic: { type: String, default: '' },
  bio: { type: String, default: '' },

  followers: [{ type: String }],
  following: [{ type: String }],
  likedVideos: [{ type: String }],
  savedVideos: [{ type: String }],

  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },

  fcmToken: {
    type: String,
    default: null,
  },

});

module.exports = mongoose.model('User', userSchema);