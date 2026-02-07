const Message = require('../models/Message');
const User = require('../models/User');
const sendPushNotification = require('../utils/sendPush');

const getUserRoom = (userId) => `user-${userId}`;
const getConversationId = (u1, u2) => [u1, u2].sort().join('-');

let ioInstance;

function initSocket(io) {
  ioInstance = io;

  io.on('connection', (socket) => {
    console.log('Socket connected:', socket.id);

    socket.on('register', ({ userId }) => {
      console.log('Register event:', { socketId: socket.id, userId });

      if (!userId) {
        console.log('Register failed: userId missing');
        socket.emit('error', { message: 'userId required' });
        return;
      }

      socket.userId = userId;
      socket.join(getUserRoom(userId));

      console.log(`User registered & joined room: ${getUserRoom(userId)}`);
      socket.emit('registered', { userId });
    });

    socket.on('send_message', async (data, ack) => {
      console.log('send_message received:', data);

      try {
        const { senderId, receiverId, text, imageUrl } = data || {};

        if (!senderId || !receiverId) {
          if (ack) ack({ success: false, error: 'Missing ids' });
          return;
        }

        if (!text && !imageUrl) {
          if (ack) ack({ success: false, error: 'Empty message' });
          return;
        }

        const msg = new Message({
          conversationId: getConversationId(senderId, receiverId),
          senderId,
          receiverId,
          text,
          imageUrl,
        });

        const savedMsg = await msg.save();
        console.log('Message saved:', savedMsg._id);

        const senderUser = await User.findOne({ userId: senderId }).lean();
        const receiverUser = await User.findOne({ userId: receiverId }).lean();

        if (receiverUser?.fcmToken) {
          try {
            console.log('Sending push notification');
            const pushResult = await sendPushNotification({
              token: receiverUser.fcmToken,
              title: senderUser?.username || 'New Message',
              body: text || '📷 Image',
              data: {
                type: 'message',
                senderId,
                senderName: senderUser?.username || '',
                senderAvatar: senderUser?.profilePic || '',
                conversationId: savedMsg.conversationId,
              },
            });

            if (pushResult.shouldDelete) {
              await User.findOneAndUpdate(
                { userId: receiverId },
                { fcmToken: null }
              );
            }

            console.log('Push notification sent');
          } catch (pushError) {
            console.log('Push notification failed:', pushError.message);
          }
        }

        const senderRoom = getUserRoom(senderId);
        const receiverRoom = getUserRoom(receiverId);


        io.to(senderRoom).emit('message', savedMsg);
        io.to(receiverRoom).emit('message', savedMsg);

        console.log('Message emitted to both rooms');

        if (ack) ack({ success: true, message: savedMsg });
      } catch (err) {
        console.error('🔥 send_message error:', err);
        if (ack) ack({ success: false, error: err.message });
      }
    });

    socket.on('typing', ({ senderId, receiverId, isTyping }) => {
      console.log('typing:', { senderId, receiverId, isTyping });

      if (!senderId || !receiverId) return;
      io.to(getUserRoom(receiverId)).emit('typing', { senderId, isTyping });
    });

    socket.on('call:start', async (data) => {
      console.log('call:start:', data);

      try {
        const { callerId, receiverId, callerName, callerAvatar, callType } = data;
        const receiverUser = await User.findOne({ userId: receiverId }).lean();

        if (receiverUser?.fcmToken) {
          try {
            console.log('📲 Sending call push notification');
            await sendPushNotification({
              token: receiverUser.fcmToken,
              title: `${callerName} is calling`,
              body: callType === 'video' ? '📹 Video Call' : '📞 Voice Call',
              data: {
                type: 'call',
                callerId,
                callerName,
                callerAvatar,
                callType,
              },
            });
            console.log('✅ Call push notification sent');
          } catch (pushError) {
            console.log('⚠️ Call push notification failed (continuing anyway):', pushError.message);
          }
        }

        console.log('📡 Emitting call:incoming to receiver');
        io.to(getUserRoom(receiverId)).emit('call:incoming', {
          callerId,
          callerName,
          callerAvatar,
          callType,
        });

        console.log('Call:incoming emitted');
      } catch (e) {
        console.error('call:start error:', e);
      }
    });

    socket.on('call:accept', (data) => {
      console.log('call:accept:', data);
      io.to(getUserRoom(data.callerId)).emit('call:accepted', data);
    });

    socket.on('call:offer', (data) => {
      console.log('call:offer');
      io.to(getUserRoom(data.receiverId)).emit('call:offer', data);
    });

    socket.on('call:answer', (data) => {
      console.log('call:answer');
      io.to(getUserRoom(data.callerId)).emit('call:answer', data);
    });

    socket.on('call:ice', (data) => {
      console.log('call:ice');
      io.to(getUserRoom(data.receiverId)).emit('call:ice', data);
    });

    socket.on('call:end', (data) => {
      console.log('call:end:', data);
      io.to(getUserRoom(data.receiverId)).emit('call:end');
      io.to(getUserRoom(data.callerId)).emit('call:end');
    });

    socket.on('disconnect', () => {
      console.log('Socket disconnected:', socket.id, 'user:', socket.userId);
    });
  });
}

function getIO() {
  if (!ioInstance) {
    throw new Error('Socket not initialized');
  }
  return ioInstance;
}

module.exports = { initSocket, getIO };
