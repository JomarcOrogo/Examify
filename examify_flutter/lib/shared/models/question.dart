class Question {
  final int id;
  final int assessmentId;
  final String body;
  final String type; // 'mcq', 'short_answer'
  final List<Option> options;
  final int points;

  Question({
    required this.id,
    required this.assessmentId,
    required this.body,
    required this.type,
    this.options = const [],
    this.points = 1,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      assessmentId: json['assessment_id'] ?? 0,
      body: json['body'] ?? json['text'] ?? '',
      type: json['type'] ?? 'mcq',
      options:
          (json['options'] as List?)?.map((o) => Option.fromJson(o)).toList() ??
          [],
      points: json['points'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'body': body,
      'type': type,
      'options': options.map((e) => e.toJson()).toList(),
      'points': points,
    };
  }
}

class Option {
  final int? id;
  final String body;
  final bool? isCorrect;

  Option({this.id, required this.body, this.isCorrect});

  factory Option.fromJson(dynamic json) {
    if (json is String) {
      return Option(body: json);
    }
    return Option(
      id: json['id'],
      body: json['body'] ?? '',
      isCorrect: json['is_correct'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'body': body, 'is_correct': isCorrect};
  }
}
