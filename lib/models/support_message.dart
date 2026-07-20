class SupportMessage {
  final String id;
  final String sender; // 'kurye' | 'restoran' | 'system' | 'superadmin'
  final String text;
  final String timestamp;

  SupportMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] ?? '',
      sender: json['sender'] ?? 'system',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
