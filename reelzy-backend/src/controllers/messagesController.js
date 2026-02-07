const Message = require('../models/Message');


const sendMessage = async (req, res) => {
  try {
    const { senderId, receiverId, text = '', imageUrl = '', conversationId } = req.body;
    if (!senderId || !receiverId) {
      return res.status(400).json({ success: false, error: 'senderId and receiverId required' });
    }

    const message = new Message({
      senderId,
      receiverId,
      text,
      imageUrl,
      conversationId: conversationId || [senderId, receiverId].sort().join('_'),
    });

    const saved = await message.save();

    return res.status(201).json({ success: true, data: saved });
  } catch (err) {
    console.error('sendMessage error:', err);
    return res.status(500).json({ success: false, error: 'Internal server error' });
  }
};


const getConversation = async (req, res) => {
  try {
    const { user1, user2, page = 1, limit = 50 } = req.query;
    if (!user1 || !user2) {
      return res.status(400).json({ success: false, error: 'user1 and user2 required' });
    }

    const conversationId = [user1, user2].sort().join('-');

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const total = await Message.countDocuments({ conversationId });
    const messages = await Message.find({ conversationId })
      .sort({ createdAt: 1 }) 
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    return res.status(200).json({
      success: true,
      conversationId,
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      length: messages.length,
      data: messages
    });
  } catch (err) {
    console.error('getConversation error:', err);
    return res.status(500).json({ success: false, error: 'Internal server error' });
  }
};




module.exports = {
  sendMessage,
  getConversation,
};
