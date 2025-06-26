class Message {
  final String? from;
  final String? to;
  final DateTime timestamp;
  final String contents;
  final String? _id;

  String? get id => _id;

  Message({
    String? id,
    required this.from,
    required this.to,
    required this.timestamp,
    required this.contents,
  }) : _id = id;

  Map<String, dynamic> toJson() => {
    if (_id != null) 'id': _id,
    'from': from,
    'to': to,
    'timestamp': timestamp.toIso8601String(),
    'contents': contents,
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String?,
      from: json['from'],
      to: json['to'],
      timestamp: DateTime.parse(json['timestamp']),
      contents: json['contents'],
    );
  }
}
