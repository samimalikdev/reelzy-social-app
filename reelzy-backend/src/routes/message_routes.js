const express = require('express');
const { 
    sendMessage, 
    getConversation 
} = require('../controllers/messagesController');

const router = express.Router();

router.post('/send', sendMessage);
router.get('/conversation', getConversation);

module.exports = router;