const mongoose = require('mongoose');

const ReportSchema = new mongoose.Schema(
  {
    reporterId: { type: String, required: true },

    targetType: {
      type: String,
      enum: ['post', 'user', 'reel'],
      required: true,
    },

    targetId: { type: String, required: true },

    reason: {
      type: String,
      enum: [
        'spam',
        'abuse',
        'harassment',
        'nudity',
        'fake',
        'hate',
        'other',
      ],
      required: true,
    },

    description: { type: String },

    status: {
      type: String,
      enum: ['pending', 'reviewed', 'action_taken'],
      default: 'pending',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Report', ReportSchema);
