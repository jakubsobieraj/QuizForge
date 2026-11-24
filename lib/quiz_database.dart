import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'quiz_data.dart';

class QuizDatabase {
  QuizDatabase._();
  static final instance = QuizDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final root = await getDatabasesPath();
    _db = await openDatabase(join(root, 'quizforge.db'), version: 3,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject TEXT NOT NULL, prompt TEXT NOT NULL,
          a TEXT NOT NULL, b TEXT NOT NULL, c TEXT NOT NULL, d TEXT NOT NULL,
          correct_index INTEGER NOT NULL)''');
        await db.execute('''CREATE TABLE results (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject TEXT NOT NULL, score INTEGER NOT NULL,
          total INTEGER NOT NULL, completed_at TEXT NOT NULL,
          review_json TEXT, original_json TEXT)''');
      }, onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE results ADD COLUMN review_json TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE results ADD COLUMN original_json TEXT');
        }
      });
    return _db!;
  }

  Future<void> addQuestion(QuizQuestion question) async {
    final db = await database;
    await db.insert('questions', question.toMap());
  }

  Future<List<QuizQuestion>> getQuestions() async {
    final db = await database;
    final rows = await db.query('questions', orderBy: 'id DESC');
    return rows.map(QuizQuestion.fromMap).toList();
  }

  Future<void> updateQuestion(QuizQuestion question) async {
    final id = question.id;
    if (id == null) throw ArgumentError('Question ID is required');
    final db = await database;
    final count = await db.update('questions', question.toMap(), where: 'id = ?', whereArgs: [id]);
    if (count != 1) throw StateError('Question no longer exists');
  }

  Future<void> deleteQuestion(int id) async {
    final db = await database;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSubject(String subject) async {
    final db = await database;
    return db.delete('questions', where: 'subject = ?', whereArgs: [subject]);
  }

  Future<void> saveResult(String subject, int score, int total,
      {List<QuizQuestion>? questions, List<int?>? answers, List<QuizQuestion>? originalQuestions}) async {
    final db = await database;
    await db.insert('results', {
      'subject': subject, 'score': score, 'total': total,
      'completed_at': DateTime.now().toIso8601String(),
      'original_json': originalQuestions == null ? null : jsonEncode([
        for (final q in originalQuestions) {
          'subject': q.subject, 'prompt': q.prompt,
          'options': q.options, 'correctIndex': q.correctIndex,
        },
      ]),
      'review_json': questions == null || answers == null ? null : jsonEncode([
        for (var i = 0; i < questions.length; i++) {
          'subject': questions[i].subject,
          'prompt': questions[i].prompt,
          'options': questions[i].options,
          'correctIndex': questions[i].correctIndex,
          'answer': answers[i],
        },
      ]),
    });
  }

  List<Map<String, dynamic>>? decodeReview(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final decoded = jsonDecode(value) as List<dynamic>;
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  List<QuizQuestion>? decodeOriginal(Object? value) {
    final rows = decodeReview(value);
    if (rows == null || rows.isEmpty) return null;
    return rows.map((row) => QuizQuestion(
      subject: row['subject'] as String,
      prompt: row['prompt'] as String,
      options: (row['options'] as List<dynamic>).cast<String>(),
      correctIndex: row['correctIndex'] as int,
    )).toList();
  }

  Future<List<Map<String, Object?>>> getResults() async {
    final db = await database;
    return db.query('results', orderBy: 'id DESC');
  }
}
