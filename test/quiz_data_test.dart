import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge/quiz_data.dart';

void main() {
  const questions = [
    QuizQuestion(subject: 'Maths', prompt: '2 + 2?',
      options: ['3', '4', '5', '6'], correctIndex: 1),
    QuizQuestion(subject: 'Maths', prompt: '3 + 3?',
      options: ['5', '7', '6', '8'], correctIndex: 2),
  ];
  test('all correct answers earn full marks', () {
    expect(scoreQuiz(questions, [1, 2]), 2);
  });
  test('incorrect and unanswered questions earn zero', () {
    expect(scoreQuiz(questions, [0, null]), 0);
  });
  test('mixed answers score correctly', () {
    expect(scoreQuiz(questions, [1, 0]), 1);
  });
  test('mismatched answer lengths are rejected', () {
    expect(() => scoreQuiz(questions, [1]), throwsArgumentError);
  });
}
