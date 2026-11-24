class QuizQuestion {
  final int? id;
  final String subject;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({this.id, required this.subject, required this.prompt,
    required this.options, required this.correctIndex});

  Map<String, Object?> toMap() => {
    'subject': subject, 'prompt': prompt,
    'a': options[0], 'b': options[1], 'c': options[2], 'd': options[3],
    'correct_index': correctIndex,
  };

  factory QuizQuestion.fromMap(Map<String, Object?> map) => QuizQuestion(
    id: map['id'] as int, subject: map['subject'] as String,
    prompt: map['prompt'] as String,
    options: [map['a'], map['b'], map['c'], map['d']].cast<String>(),
    correctIndex: map['correct_index'] as int,
  );
}

int scoreQuiz(List<QuizQuestion> questions, List<int?> answers) {
  if (questions.length != answers.length) {
    throw ArgumentError('Questions and answers must have equal lengths');
  }
  var score = 0;
  for (var i = 0; i < questions.length; i++) {
    if (answers[i] == questions[i].correctIndex) score++;
  }
  return score;
}
