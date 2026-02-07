const express = require('express');
const router = express.Router();
const {
  shareReel,
  toggleReelSave,
  toggleReelLike,
  getLikedReels,
  getSavedReels,
  getMyVideos,
  addReelComment,
  getReelComments,
  toggleReelCommentLike,
  addReelCommentReply,
  deleteReelComment
} = require('../controllers/reel.controller');

router.post('/media/:reelId/like', toggleReelLike);
router.post('/media/:reelId/save', toggleReelSave);
router.post('/media/:reelId/share', shareReel);

router.get('/reels/liked/:userId', getLikedReels);
router.get('/reels/saved/:userId', getSavedReels);
router.get('/media/my-videos/:userId', getMyVideos);

router.post('/reel/:reelId/comment', addReelComment);
router.get('/reel/:reelId/comments', getReelComments);
router.post('/reel/:reelId/comment/:commentId/like', toggleReelCommentLike);
router.post('/reel/:reelId/comment/:commentId/reply', addReelCommentReply);
router.delete('/reel/:reelId/comment/:commentId', deleteReelComment);


module.exports = router;
