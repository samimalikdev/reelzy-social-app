class Message {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });
}
