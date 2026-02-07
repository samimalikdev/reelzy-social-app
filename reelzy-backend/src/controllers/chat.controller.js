const Message = require('../models/Message');
const Messgae = require('../models/Message')
const User = require('../models/User')

const getChatConversations = async (req, res) => {
            const {userId} = req.params;

    try {

        const chatList = await Message.find({
            $or: [
                { senderId: userId},
                 { receiverId: userId},
            ]
    }).sort( {createdAt: -1} );

        const chatMap = new Map();

        for (const msg of chatList) {
            const targetId = msg.senderId == userId ? msg.receiverId : msg.senderId;

         if (!chatMap.has(targetId)) {
               chatMap.set(targetId, {
                targetId,
                lastMessage: msg.text,
                lastMessageTime: msg.createdAt
            })
         }
        }

        const targetIds = Array.from(chatMap.keys());

        const users = await User.find({ userId: { $in: targetIds }});

        const result = users.map( e => ({
            user: e,
            lastMessage: chatMap.get(e.userId).lastMessage,
            lastMessageTime: chatMap.get(e.userId).lastMessageTime,
        }));

        res.status(200).json({
            success: true,
            chats: result
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        })
    }
}


module.exports = { getChatConversations };
