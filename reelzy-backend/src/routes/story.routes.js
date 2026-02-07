const express = require('express');
const router = express.Router();

const {
  uploadStory,
  getStoriesFeed
} = require('../controllers/story.controller');

router.post('/upload-story', uploadStory);

router.get('/feed/:userId', getStoriesFeed);

module.exports = router;
