const Report = require('../models/Report');

const createReport = async (req, res) => {
  try {
    const { reporterId, targetType, targetId, reason, description } = req.body;

    if (!reporterId || !targetType || !targetId || !reason) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
      });
    }

    const report = await Report.create({
      reporterId,
      targetType,
      targetId,
      reason,
      description,
    });

    res.json({
      success: true,
      message: 'Report submitted',
      data: report,
    });
  } catch (err) {
    console.error('createReport error:', err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
};

module.exports = { createReport };
