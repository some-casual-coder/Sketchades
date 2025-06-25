class User {
  final String? _id;
  final String username;
  final String photoUrl;
  final bool active;
  final DateTime lastseen;

  String? get id => _id;

  User({
    String? id,
    required this.username,
    required this.photoUrl,
    required this.active,
    required this.lastseen,
  }) : _id = id;

  Map<String, dynamic> toJson() => {
    if (_id != null) 'id': _id,
    "username": username,
    "photo_url": photoUrl,
    'active': active,
    'last_seen': lastseen.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      username: json['username'],
      photoUrl: json['photo_url'],
      active: json['active'],
      lastseen: DateTime.parse(json['last_seen']),
    );
  }
}
