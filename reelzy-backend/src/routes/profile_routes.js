const express = require('express');
const { 
    toggleFollow,
    getUserProfile,
    createUser,
    updateProfile,
    uploadProfileToS3,
    saveFcmToken,
    getAllUsers
} = require('../controllers/profileController');

const router = express.Router();

router.post('/toggleFollow/:targetUserId', toggleFollow);
router.get('/getUserProfile/:userId', getUserProfile);
router.post('/create-user', createUser);
router.patch('/update-profile/:userId', updateProfile);
router.post('/upload/profile-pic', uploadProfileToS3);
router.post('/save-fcm-token', saveFcmToken);
router.get('/getUsers', getAllUsers);

module.exports = router;