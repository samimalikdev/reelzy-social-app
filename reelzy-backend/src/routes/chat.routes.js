const express = require('express');
const router = express.Router();

const {
  getChatConversations
} = require('../controllers/chat.controller');

router.get('/:userId', getChatConversations);

module.exports = router;
