const express = require('express');
const { 
    getAllMedia,
    getMediaById,
    uploadMedia
} = require('../controllers/mediaController');

const router = express.Router();

router.get('/getMedia', getAllMedia);
router.get('/getMediaById', getMediaById);
router.post('/upload', uploadMedia);

module.exports = router;