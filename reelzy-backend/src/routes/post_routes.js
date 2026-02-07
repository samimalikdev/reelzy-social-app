const express = require('express');
const { 
    addPost,
    getAllPosts,
    getPostsByUserId,
    toggleLike,
    toggleSave,
    sharePost
} = require('../controllers/postController');

const router = express.Router();

router.post('/addPost', addPost);
router.get('/getPosts', getAllPosts);
router.get('/getPostsByUserId/:userId', getPostsByUserId);
router.post('/toggleLike/:postId', toggleLike);
router.post('/toggleSave/:postId', toggleSave);
router.post('/sharePost/:postId', sharePost);

module.exports = router;