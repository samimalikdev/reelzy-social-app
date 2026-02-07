const mongoose = require('mongoose');

const mediaSchema = new mongoose.Schema({
    userId: {
        type: String,
        required: true,
        index: true
    },
    originalname: {
        type: String,
        required: true
    },
    filename: {
        type: String,
        required: true
    },
    url: {
        type: String,
        required: true
    },
    key: {
        type: String,
        required: true
    },
    bucket: {
        type: String,
        required: true
    },
    mimetype: {
        type: String,
        required: true
    },
    size: {
        type: Number,
        required: true
    },
    mediaType: {
        type: String,
        enum: ['image', 'video'],
        required: true
    },
    extension: {
        type: String,
        required: true
    },

    thumbnail: {
        type: String,
    },
    
    metadata: {
        caption: {
            type: String,
            required: true
        },
        hashtags: {
            type: [String],
            default: []
        }
    },

    uploadedAt: {
        type: Date,
        default: Date.now
    },
    uploadedBy: {
        type: String,
        required: true
    }
}, {
    timestamps: true
});

const Media = mongoose.model('Media', mediaSchema);

module.exports = Media;