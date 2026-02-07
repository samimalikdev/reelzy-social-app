const { upload } = require('../middleware/upload');
const { convertToCDN } = require('../services/cdn.service');

const uploadToS3 = (req, res) => {
  return new Promise((resolve, reject) => {
    const uploadSingle = upload.single('file');

    uploadSingle(req, res, (error) => {
      if (error) {
        return reject({
          status: 400,
          message: error.message,
        });
      }

      if (!req.file) {
        return reject({
          status: 400,
          message: 'No file uploaded',
        });
      }

      const cdnUrl = convertToCDN(req.file.location);

      resolve({
        url: cdnUrl,
        file: req.file,
      });
    });
  });
};

module.exports = uploadToS3;
