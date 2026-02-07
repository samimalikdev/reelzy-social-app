const path = require('path');
const crypto = require('crypto');

const generateFileName = (originalname) => {
    const timestamp = Date.now();
    const randomBytes = crypto.randomBytes(16).toString('hex');
    const extension = path.extname(originalname).toLowerCase();
    const baseName = path.basename(originalname, extension);
    const formattedName = baseName.replace(/[^a-zA-Z0-9]/g, '_');

    const isVideo = ['.mp4', '.avi', '.mov', '.mkv', '.flv', '.webm'].includes(extension);
    const folder = isVideo ? 'videos' : 'images';
    return `${folder}/${timestamp}_${randomBytes}_${formattedName}${extension}`;
};

module.exports = { generateFileName };