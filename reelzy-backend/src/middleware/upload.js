const multer = require('multer');
const multerS3 = require('multer-s3');
const { s3Client } = require('../config/s3');
const { generateFileName } = require('../utils/helpers');
const path = require("path");

const videoExts = [".mp4", ".mov", ".avi", ".mkv"];
const audioExts = [".mp3", ".wav", ".aac"];
const imageExts = [".jpg", ".jpeg", ".png", ".gif"];

const filterFiles = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();

  if (file.mimetype.startsWith("image/") || imageExts.includes(ext)) {
    cb(null, true);
  } else if (file.mimetype.startsWith("video/") || videoExts.includes(ext)) {
    cb(null, true);
  } else if (file.mimetype.startsWith("audio/") || audioExts.includes(ext)) {
    cb(null, true);
  } else {
    console.error(`File type not allowed: ${file.mimetype} Extension: ${ext}`);
    cb(new Error("Invalid file type"), false);
  }
};

const upload = multer({
    storage: multerS3({
        s3: s3Client,
        bucket: process.env.AWS_S3_BUCKET,
        contentType: (req, file, cb) => {
            const ext = path.extname(file.originalname).toLowerCase();
            if (file.mimetype === 'application/octet-stream') {
                if (['.mp4', '.mov'].includes(ext)) {
                    cb(null, 'video/mp4');
                } else if (['.jpg', '.jpeg'].includes(ext)) {
                    cb(null, 'image/jpeg');
                } else {
                    multerS3.AUTO_CONTENT_TYPE(req, file, cb);
                }
            } else {
                multerS3.AUTO_CONTENT_TYPE(req, file, cb);
            }
        },
        key: (req, file, cb) => {
            const fileName = generateFileName(file.originalname);
            cb(null, fileName);
        },
        metadata: (req, file, cb) => {
            cb(null, { originalname: file.originalname });
        }
    }),
    
    limits: {
        fileSize: 100 * 1024 * 1024,
    },
    fileFilter: filterFiles,
});

module.exports = { upload };