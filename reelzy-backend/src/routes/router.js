const express = require('express');
const mediaRoutes = require('./media_routes');
const postRoutes = require('./post_routes');
const commentRoutes = require('./comment_routes');
const profileRoutes = require('./profile_routes');
const messageRoutes = require('./message_routes');
const reelRoutes = require('./reel.routes')
const storyRoutes = require('./story.routes');
const reportRoutes = require('./report.routes');
const chatRoutes = require('./chat.routes');

const router = express.Router();

router.use('/', mediaRoutes);
router.use('/', postRoutes);
router.use('/', commentRoutes);
router.use('/', profileRoutes);
router.use('/', messageRoutes);
router.use('/', reelRoutes);
router.use('/', storyRoutes);
router.use('/', reportRoutes);
router.use('/chats', chatRoutes);

module.exports = router;