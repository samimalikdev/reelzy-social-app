const admin = require('./firebase');

async function sendPushNotification({ token, title, body, data }) {
  if (!token) {
    console.log('No FCM token provided');
    return { success: false, reason: 'no_token' };
  }

  try {
    const response = await admin.messaging().send({
      token,
      notification: {
        title,
        body,
      },
      data,
      android: {
        priority: 'high',
      },
    });

    console.log('Push notification sent successfully:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.log('Push notification failed:', error.code, error.message);

    if (
      error.code === 'messaging/registration-token-not-registered' ||
      error.code === 'messaging/invalid-registration-token'
    ) {
      console.log('🗑️ Token is invalid - should be removed from database');
      return { success: false, reason: 'invalid_token', shouldDelete: true };
    }

    return { success: false, reason: error.code };
  }
}

module.exports = sendPushNotification;