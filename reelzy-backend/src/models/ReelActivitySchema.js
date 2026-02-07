const mongoose = require('mongoose');

const ReelActivitySchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true,
  },

  likedReels: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Reel',
    },
  ],

  savedReels: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Reel',
    },
  ],
}, { timestamps: true });

module.exports = mongoose.model('ReelActivity', ReelActivitySchema);
