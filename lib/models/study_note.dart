enum NoteType { text, voice }

class StudyNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final String taskId;
  final String? sessionId; // Links note to specific pomodoro session
  final NoteType type;
  final String? voicePath; // Path to voice recording file if type is voice

  StudyNote({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.taskId,
    this.sessionId,
    required this.type,
    this.voicePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'taskId': taskId,
    'sessionId': sessionId,
    'type': type.toString(),
    'voicePath': voicePath,
  };

  factory StudyNote.fromJson(Map<String, dynamic> json) => StudyNote(
    id: json['id'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
    taskId: json['taskId'],
    sessionId: json['sessionId'],
    type: NoteType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => NoteType.text,
    ),
    voicePath: json['voicePath'],
  );
}
