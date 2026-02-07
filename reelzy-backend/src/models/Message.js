const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
    conversationId: {
        type: String,
        required: true,
    },
    senderId: {
        type: String,
        required: true, 
    },
    receiverId: {
        type: String,
        required: true,
    },
    text: {
        type: String,
        required: true,
    },
    impageMediaUrl: {
        type: String,
    },
    isRead: {
        type: Boolean,
        default: false,
    },
    CreatedAt: {
        type: Date,
        default: Date.now,
    },
    timestamp: {
        type: Date,
        default: Date.now,
    },

});

module.exports = mongoose.model('Message', messageSchema);