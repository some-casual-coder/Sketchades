class User {
  String? _id;
  String? username;
  String? photoUrl;
  bool? active;
  DateTime? lastseen;

  String? get id => _id;

  User({
    required this.username,
    required this.photoUrl,
    required this.active,
    required this.lastseen,
  });

  Map<String, dynamic> toJson() => {
    "username": username,
    "photo_url": photoUrl,
    'active': active,
    'last_seen': lastseen,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
      username: json['username'],
      photoUrl: json['photo_url'],
      active: json['active'],
      lastseen: json['last_seen'],
    );
    user._id = json['id'];
    return user;
  }
}
