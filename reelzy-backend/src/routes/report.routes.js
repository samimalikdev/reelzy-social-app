const express = require('express');
const router = express.Router();
const { createReport } = require('../controllers/report.controller');

router.post('/report', createReport);

module.exports = router;
