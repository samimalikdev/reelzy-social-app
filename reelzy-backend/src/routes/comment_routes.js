const express = require('express');
const { 
    addPostComment,
    getPostComments,
    deleteComment,
    toggleCommentLike,
    addCommentReply
} = require('../controllers/commentController');

const router = express.Router();

router.post('/addPostComment/:postId', addPostComment);
router.get('/getPostComments/:postId', getPostComments);
router.delete('/deletePostComment/:postId/:commentId', deleteComment);
router.post('/toggleCommentLike/:postId/:commentId', toggleCommentLike);
router.post('/addCommentReply/:postId/:commentId', addCommentReply);

module.exports = router;