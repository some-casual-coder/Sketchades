enum Typing { start, stop }

// TODO make this DRY
extension TypingParser on Typing {
  String value() {
    return toString().split('.').last;
  }

  static Typing fromString(String status) {
    return Typing.values.firstWhere((element) => element.value() == status);
  }
}

class TypingEvent {
  final String? from;
  final String? to;
  final Typing event;
  String? _id;

  String? get id => _id;

  TypingEvent({required this.from, required this.to, required this.event});

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'event': event.value(),
  };

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    var event = TypingEvent(
      from: json['from'],
      to: json['to'],
      event: TypingParser.fromString(json['event']),
    );
    event._id = json['id'];
    return event;
  }
}
