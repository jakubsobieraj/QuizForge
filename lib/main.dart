import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quiz_data.dart';
import 'quiz_database.dart';
import 'gemini_quiz_service.dart';

const _navy = Color(0xFF15172C);
const _surface = Color(0xFF24243E);
const _purple = Color(0xFFA36CFF);
Color _muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
Color _accent(BuildContext context) => Theme.of(context).brightness == Brightness.light
    ? const Color(0xFF7045BA) : _purple;
Color _feedback(BuildContext context, bool correct) =>
    Theme.of(context).brightness == Brightness.light
      ? (correct ? const Color(0xFF14643E) : const Color(0xFFB42340))
      : (correct ? const Color(0xFF5CE0A2) : const Color(0xFFFF8294));

class QuizSettings {
  static final lightMode = ValueNotifier<bool>(false);
  static final highlightCorrectAnswer = ValueNotifier<bool>(false);
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    lightMode.value = prefs.getBool('light_mode') ?? false;
    highlightCorrectAnswer.value = prefs.getBool('highlight_correct_answer') ?? false;
  }
  static Future<void> setLightMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool('light_mode', value)) {
      throw StateError('Could not save theme');
    }
    lightMode.value = value;
  }
  static Future<void> setHighlight(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highlight_correct_answer', value);
    highlightCorrectAnswer.value = value;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuizSettings.load();
  runApp(const QuizForgeApp());
}

class QuizForgeApp extends StatelessWidget {
  const QuizForgeApp({super.key});
  ThemeData _theme(bool light) {
    final brightness = light ? Brightness.light : Brightness.dark;
    final background = light ? const Color(0xFFF5F3FA) : _navy;
    final surface = light ? Colors.white : _surface;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _purple, brightness: brightness, surface: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: light ? const Color(0xFF201C32) : Colors.white,
        centerTitle: false, elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF7045BA),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: QuizSettings.lightMode,
    builder: (context, light, _) => MaterialApp(
      title: 'QuizForge',
      debugShowCheckedModeBanner: false,
      theme: _theme(true),
      darkTheme: _theme(false),
      themeMode: light ? ThemeMode.light : ThemeMode.dark,
      home: const HomeScreen(),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Card(child: ValueListenableBuilder<bool>(
        valueListenable: QuizSettings.highlightCorrectAnswer,
        builder: (context, enabled, _) => SwitchListTile(
          secondary: Icon(Icons.check_circle_outline, color: _accent(context)),
          title: const Text('Highlight correct answer'),
          subtitle: const Text('Flash your selected answer green when correct, red when incorrect.'),
          value: enabled,
          onChanged: (value) async {
            try {
              await QuizSettings.setHighlight(value);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not save this setting.')));
              }
            }
          },
        ),
      )),
      const SizedBox(height: 12),
      Card(child: ValueListenableBuilder<bool>(
        valueListenable: QuizSettings.lightMode,
        builder: (context, enabled, _) => SwitchListTile(
          secondary: Icon(Icons.light_mode_outlined, color: _accent(context)),
          title: const Text('Light mode'),
          subtitle: const Text('Use a brighter appearance throughout QuizForge.'),
          value: enabled,
          onChanged: (value) async {
            try {
              await QuizSettings.setLightMode(value);
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not save this setting.')));
              }
            }
          },
        ),
      )),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Answer feedback appears for about 0.7 seconds after pressing Next question or Finish quiz. '
          'The correct answer is not revealed if you choose incorrectly.',
          style: TextStyle(color: _muted(context))),
      ),
    ]),
  );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({required this.icon, required this.label, required this.onTap,
    required this.colors});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final List<Color> colors;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft,
            end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 35, color: Colors.white),
            const SizedBox(height: 12),
            Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700,
                fontSize: 15, color: Colors.white)),
          ]),
        ),
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<QuizQuestion>> questions;
  @override
  void initState() { super.initState(); refresh(); }
  void refresh() {
    setState(() {
      questions = QuizDatabase.instance.getQuestions();
    });
  }

  Future<bool> confirmAndDeleteSubject(String subject, int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text('Delete "$subject" and all $count saved questions? '
            'This cannot be undone. Quiz history will be kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;

    try {
      await QuizDatabase.instance.deleteSubject(subject);
      if (!mounted) return false;
      refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "$subject" and its $count questions.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the subject. Please try again.')),
        );
      }
    }
    // The refreshed FutureBuilder removes the subject after SQLite succeeds.
    // Returning false avoids Dismissible removing the tile a second time.
    return false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(children: [
        Icon(Icons.school_outlined, color: _accent(context)),
        SizedBox(width: 10),
        Text('QuizForge', style: TextStyle(fontWeight: FontWeight.w700)),
      ]),
      actions: [IconButton(
        tooltip: 'Settings',
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ), const SizedBox(width: 8)],
    ),
    body: FutureBuilder<List<QuizQuestion>>(
      future: questions,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load questions: ${snapshot.error}'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final all = snapshot.data!;
        final subjects = all.map((q) => q.subject).toSet().toList()..sort();
        return ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), children: [
          const Text('Turn your notes\ninto quizzes.',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.15)),
          const SizedBox(height: 12),
          Text('AI-powered revision for better results.',
            style: TextStyle(color: _muted(context), fontSize: 16)),
          const SizedBox(height: 8),
          Text('${all.length} saved questions  •  ${subjects.length} subjects',
            style: TextStyle(color: _muted(context))),
          const SizedBox(height: 28),
          Row(children: [
            Expanded(child: _HomeAction(
              icon: Icons.library_books_outlined, label: 'Question\nbank',
              colors: const [Color(0xFF873CC1), Color(0xFF552B91)],
              onTap: () async {
                await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QuestionBankScreen()));
                if (mounted) refresh();
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: _HomeAction(
              icon: Icons.auto_awesome, label: 'Generate\nwith AI',
              colors: const [Color(0xFF5469D9), Color(0xFF34388E)],
              onTap: () async {
                await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const GenerateQuizScreen()));
                if (mounted) refresh();
              },
            )),
          ]),
          const SizedBox(height: 14),
          Card(child: ListTile(
            leading: Icon(Icons.bar_chart_rounded, color: _accent(context)),
            title: const Text('Quiz history', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistoryScreen())),
          )),
          const SizedBox(height: 28),
          const Text('Your subjects',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (subjects.isEmpty) Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No questions yet. Generate a quiz or create a question.',
              style: TextStyle(color: _muted(context))),
          ),
          for (final subject in subjects) Dismissible(
            key: ValueKey('subject:$subject'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.only(right: 24),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: const Color(0xFF9E2936),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            confirmDismiss: (_) => confirmAndDeleteSubject(
              subject, all.where((q) => q.subject == subject).length),
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Icon(Icons.folder_outlined, color: _accent(context)),
                title: Text(subject, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${all.where((q) => q.subject == subject).length} questions',
                  style: TextStyle(color: _muted(context))),
                trailing: Icon(Icons.chevron_right, color: _muted(context)),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => QuizScreen(subject: subject,
                    questions: all.where((q) => q.subject == subject).toList()..shuffle()),
                )).then((_) { if (mounted) refresh(); }),
              ),
            ),
          ),
        ]);
      },
    ),
  );
}

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});
  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  late Future<List<QuizQuestion>> questions;
  String? selectedSubject;
  bool deleting = false;

  @override
  void initState() {
    super.initState();
    questions = QuizDatabase.instance.getQuestions();
  }

  void refresh() {
    setState(() => questions = QuizDatabase.instance.getQuestions());
  }

  Future<void> edit([QuizQuestion? question]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) =>
      AddQuestionScreen(question: question, initialSubject: selectedSubject)));
    if (mounted) refresh();
  }

  Future<void> remove(QuizQuestion question) async {
    if (deleting || question.id == null) return;
    setState(() => deleting = true);
    try {
      final confirmed = await showDialog<bool>(context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete question?'),
          content: Text('Remove this question from "${question.subject}"? Quiz history will be kept.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
          ],
        ));
      if (confirmed != true || !mounted) return;
      await QuizDatabase.instance.deleteQuestion(question.id!);
      if (!mounted) return;
      refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question deleted.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete question. Please try again.')));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Question Bank')),
    body: FutureBuilder<List<QuizQuestion>>(
      future: questions,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Could not load questions.'),
            TextButton(onPressed: refresh, child: const Text('Try again')),
          ]));
        }
        final all = snapshot.data ?? <QuizQuestion>[];
        final subjects = all.map((q) => q.subject).toSet().toList()..sort();
        final active = subjects.contains(selectedSubject) ? selectedSubject : null;
        final visible = all.where((q) => active == null || q.subject == active).toList();
        return ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Manage your revision material', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Filter by subject', border: OutlineInputBorder()),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              isExpanded: true, value: active,
              hint: const Text('All subjects'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('All subjects')),
                for (final subject in subjects) DropdownMenuItem(value: subject, child: Text(subject, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (value) => setState(() => selectedSubject = value),
            )),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: deleting ? null : () => edit(), icon: const Icon(Icons.add), label: const Text('Create a question')),
          const SizedBox(height: 16),
          Text('${visible.length} saved questions', style: TextStyle(color: _muted(context))),
          if (visible.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('No saved questions yet. Create a question or generate a quiz with AI.')),
          for (final q in visible) Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(q.subject, style: TextStyle(color: _muted(context))),
                const SizedBox(height: 8),
                Text(q.prompt, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                for (var i = 0; i < q.options.length; i++) Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(i == q.correctIndex ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                      size: 20, color: i == q.correctIndex ? _feedback(context, true) : _muted(context)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${String.fromCharCode(65 + i)}. ${q.options[i]}${i == q.correctIndex ? ' (Correct)' : ''}',
                      style: TextStyle(color: i == q.correctIndex ? _feedback(context, true) : null))),
                  ]),
                ),
                const Divider(),
                Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
                  TextButton.icon(onPressed: deleting ? null : () => edit(q), icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
                  TextButton.icon(onPressed: deleting ? null : () => remove(q), icon: const Icon(Icons.delete_outline), label: const Text('Delete')),
                ]),
              ],
            )),
          ),
        ]);
      },
    ),
  );
}

class AddQuestionScreen extends StatefulWidget {
  final QuizQuestion? question;
  final String? initialSubject;
  const AddQuestionScreen({super.key, this.question, this.initialSubject});
  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final formKey = GlobalKey<FormState>();
  final subject = TextEditingController();
  final prompt = TextEditingController();
  final options = List.generate(4, (_) => TextEditingController());
  int correct = 0;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    subject.text = q?.subject ?? widget.initialSubject ?? '';
    if (q != null) {
      prompt.text = q.prompt;
      for (var i = 0; i < 4; i++) { options[i].text = q.options[i]; }
      correct = q.correctIndex;
    }
  }

  @override
  void dispose() {
    subject.dispose(); prompt.dispose();
    for (final controller in options) { controller.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.question == null ? 'New question' : 'Edit question')),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
      TextFormField(controller: subject, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
        validator: requiredText),
      const SizedBox(height: 14),
      TextFormField(controller: prompt, maxLines: 3,
        decoration: const InputDecoration(labelText: 'Question', border: OutlineInputBorder()), validator: requiredText),
      const SizedBox(height: 18),
      const Text('Answer options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(top: 10),
        child: TextFormField(controller: options[i], validator: requiredText,
          decoration: InputDecoration(labelText: 'Option ${String.fromCharCode(65 + i)}', border: const OutlineInputBorder()))),
      const SizedBox(height: 18),
      DropdownButtonFormField<int>(initialValue: correct,
        decoration: const InputDecoration(labelText: 'Correct answer', border: OutlineInputBorder()),
        items: List.generate(4, (i) => DropdownMenuItem(value: i, child: Text('Option ${String.fromCharCode(65 + i)}'))),
        onChanged: (value) => setState(() => correct = value ?? 0)),
      const SizedBox(height: 22),
      FilledButton(onPressed: saving ? null : () async {
        if (!formKey.currentState!.validate()) return;
        setState(() => saving = true);
        try {
          final question = QuizQuestion(
            id: widget.question?.id, subject: subject.text.trim(), prompt: prompt.text.trim(),
            options: options.map((c) => c.text.trim()).toList(), correctIndex: correct);
          if (widget.question == null) {
            await QuizDatabase.instance.addQuestion(question);
          } else {
            await QuizDatabase.instance.updateQuestion(question);
          }
          if (context.mounted) Navigator.pop(context);
        } catch (error) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save: $error')));
        } finally { if (mounted) setState(() => saving = false); }
      }, child: Text(saving ? 'Saving...' : 'Save question')),
    ])),
  );
}

String? requiredText(String? text) => text == null || text.trim().isEmpty ? 'This field is required' : null;

class QuizScreen extends StatefulWidget {
  final String subject;
  final List<QuizQuestion> questions;
  final List<QuizQuestion>? originalQuestions;
  const QuizScreen({super.key, required this.subject, required this.questions,
    this.originalQuestions});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0;
  late final List<int?> answers = List.filled(widget.questions.length, null);
  bool submitting = false;
  bool showingFeedback = false;
  int? feedbackOption;

  void chooseAnswer(int value) {
    if (submitting || showingFeedback) return;
    setState(() => answers[index] = value);
  }

  Future<void> advanceQuestion() async {
    if (answers[index] == null || submitting || showingFeedback) return;

    // Only reveal the selected answer after Next/Finish is pressed.
    if (QuizSettings.highlightCorrectAnswer.value) {
      setState(() {
        feedbackOption = answers[index];
        showingFeedback = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        showingFeedback = false;
        feedbackOption = null;
      });
    }

    if (index < widget.questions.length - 1) {
      setState(() => index++);
      return;
    }

    setState(() => submitting = true);
    final score = scoreQuiz(widget.questions, answers);
    try {
      await QuizDatabase.instance.saveResult(
        widget.subject, score, widget.questions.length,
        questions: widget.questions, answers: answers,
        originalQuestions: widget.originalQuestions ?? widget.questions);
      if (!mounted) return;
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => ResultScreen(
          questions: widget.questions, answers: answers, score: score,
          originalQuestions: widget.originalQuestions ?? widget.questions)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save result: $error')));
        setState(() => submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[index];
    return Scaffold(
      appBar: AppBar(title: Text(widget.subject)),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Question ${index + 1} of ${widget.questions.length}',
            style: TextStyle(color: _muted(context))),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: (index + 1) / widget.questions.length,
            minHeight: 5, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 22),
          Expanded(child: ListView(children: [
            Text(question.prompt,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
            const SizedBox(height: 26),
            for (var i = 0; i < 4; i++) Builder(builder: (context) {
              final flashing = showingFeedback && feedbackOption == i;
              final correct = i == question.correctIndex;
              final highlight = flashing
                ? (Theme.of(context).brightness == Brightness.light
                    ? (correct ? const Color(0xFFDDF5E6) : const Color(0xFFFFE1E6))
                    : (correct ? const Color(0xFF195D42) : const Color(0xFF792B3E)))
                : Theme.of(context).colorScheme.surface;
              final outline = flashing
                ? _feedback(context, correct)
                : (answers[index] == i ? _accent(context) : Colors.transparent);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(color: highlight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: outline, width: 1.5)),
                  child: RadioListTile<int>(
                    title: Text(question.options[i]),
                    secondary: flashing ? Icon(correct ? Icons.check_circle : Icons.cancel,
                      color: _feedback(context, correct)) : null,
                    value: i,
                    // RadioGroup is preferred by newer Flutter versions, but
                    // this preserves compatibility with the project's current API.
                    groupValue: answers[index],
                    onChanged: (submitting || showingFeedback)
                      ? null : (value) { if (value != null) chooseAnswer(value); },
                  ),
                ),
              );
            }),
          ])),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: answers[index] == null || submitting || showingFeedback
              ? null : advanceQuestion,
            child: Text(index == widget.questions.length - 1
              ? 'Finish quiz' : 'Next question'),
          ),
        ]),
      )),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final List<QuizQuestion> questions;
  final List<int?> answers;
  final int score;
  final String? subject;
  final bool historical;
  final List<QuizQuestion>? originalQuestions;
  List<QuizQuestion> get fullQuestions => originalQuestions ?? questions;
  const ResultScreen({super.key, required this.questions, required this.answers,
    required this.score, this.subject, this.historical = false, this.originalQuestions});

  List<QuizQuestion> get incorrectQuestions => [
    for (var i = 0; i < questions.length; i++)
      if (answers[i] != questions[i].correctIndex) questions[i],
  ];

  void retake(BuildContext context, {bool incorrectOnly = false}) {
    final source = incorrectOnly ? incorrectQuestions : fullQuestions;
    if (source.isEmpty) return;
    final shuffled = List<QuizQuestion>.of(source)..shuffle();
    // Avoid an identical question order when there is more than one question.
    if (shuffled.length > 1 &&
        shuffled.asMap().entries.every((entry) =>
          identical(entry.value, source[entry.key]))) {
      final first = shuffled.removeAt(0);
      shuffled.add(first);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(
      subject: subject ?? questions.first.subject, questions: shuffled,
      originalQuestions: fullQuestions)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(historical ? 'Previous results' : 'Your results')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('$score / ${questions.length}', style: const TextStyle(
        fontSize: 42, fontWeight: FontWeight.bold)),
      Text(questions.isEmpty ? 'No questions recorded' :
        '${(score / questions.length * 100).round()}% correct',
        style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 20),
      for (var i = 0; i < questions.length; i++) Card(child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(answers[i] == questions[i].correctIndex
              ? Icons.check_circle : Icons.cancel,
              color: _feedback(context, answers[i] == questions[i].correctIndex)),
            const SizedBox(width: 8),
            Expanded(child: Text('Question ${i + 1}', style: TextStyle(
              color: _muted(context), fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 8),
          Text(questions[i].prompt,
            style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Your answer: ${answers[i] == null ? 'Not answered' : questions[i].options[answers[i]!]}'),
          Text('Correct answer: ${questions[i].options[questions[i].correctIndex]}',
            style: TextStyle(color: _feedback(context, answers[i] == questions[i].correctIndex))),
        ]))),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: fullQuestions.isEmpty ? null : () => retake(context),
        icon: const Icon(Icons.refresh),
        label: Text('Retake full quiz (${fullQuestions.length})')),
      if (incorrectQuestions.isNotEmpty) ...[
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => retake(context, incorrectOnly: true),
          icon: const Icon(Icons.refresh),
          label: Text('Retake incorrect questions (${incorrectQuestions.length})'),
        ),
      ],
      const SizedBox(height: 10),
      OutlinedButton(onPressed: () => Navigator.pop(context),
        child: const Text('Back')),
    ]),
  );
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> openHistory(BuildContext context, Map<String, Object?> item) async {
    final subject = item['subject'] as String;
    final review = QuizDatabase.instance.decodeReview(item['review_json']);
    if (review == null) {
      if (!context.mounted) return;
      await showDialog<void>(context: context, builder: (dialogContext) =>
        AlertDialog(
          title: const Text('Earlier quiz attempt'),
          content: Text('This attempt scored ${item['score']}/${item['total']}. '
            'QuizForge did not save individual answers for attempts made before '
            'this update, so the original answer review cannot be restored.'),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'))],
        ));
      return;
    }
    final questions = <QuizQuestion>[];
    final answers = <int?>[];
    for (final row in review) {
      questions.add(QuizQuestion(
        subject: row['subject'] as String,
        prompt: row['prompt'] as String,
        options: (row['options'] as List<dynamic>).cast<String>(),
        correctIndex: row['correctIndex'] as int,
      ));
      answers.add(row['answer'] as int?);
    }
    if (!context.mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(
      questions: questions, answers: answers, score: item['score'] as int,
      subject: subject, historical: true,
      originalQuestions: QuizDatabase.instance.decodeOriginal(item['original_json']))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quiz history')),
    body: FutureBuilder<List<Map<String, Object?>>>(
      future: QuizDatabase.instance.getResults(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Could not load history: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Text('Complete a quiz to see your results.'));
        return ListView.builder(itemCount: snapshot.data!.length,
          itemBuilder: (context, i) {
            final item = snapshot.data![i];
            return Card(child: ListTile(
              title: Text(item['subject'] as String),
              subtitle: Text((item['completed_at'] as String).split('T').first),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${item['score']}/${item['total']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: _muted(context)),
              ]),
              onTap: () => openHistory(context, item),
            ));
          });
      },
    ),
  );
}


class GenerateQuizScreen extends StatefulWidget {
  const GenerateQuizScreen({super.key});

  @override
  State<GenerateQuizScreen> createState() => _GenerateQuizScreenState();
}

class _GenerateQuizScreenState extends State<GenerateQuizScreen> {
  final topicController = TextEditingController();
  final notesController = TextEditingController();
  bool useNotes = false;
  bool expandOutline = true;
  int count = 5;
  int completed = 0;
  bool generating = false;
  bool readingPhoto = false;
  final picker = ImagePicker();
  bool get busy => generating || readingPhoto;

  Future<void> readPhotos(ImageSource source) async {
    setState(() { readingPhoto = true; });
    try {
      final List<XFile> photos;
      if (source == ImageSource.camera) {
        final photo = await picker.pickImage(source: source, maxWidth: 2000, imageQuality: 85);
        photos = photo == null ? [] : [photo];
      } else {
        photos = await picker.pickMultiImage(maxWidth: 2000, imageQuality: 85);
      }
      if (!mounted || photos.isEmpty) return;
      if (photos.length > 5) throw const FormatException('Select up to five photos at a time.');
      for (final photo in photos) {
        final bytes = await photo.readAsBytes();
        final mime = bytes.length >= 3 && bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255
            ? 'image/jpeg'
            : bytes.length >= 8 && bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71
                ? 'image/png' : null;
        if (mime == null) throw const FormatException('Use a JPEG or PNG photo. Try a screenshot if HEIC is not converted.');
        final text = await GeminiQuizService.transcribePhoto(bytes, mime);
        if (!mounted) return;
        final existing = notesController.text.trim();
        final combined = existing.isEmpty ? text : '$existing\n\n$text';
        if (combined.length > 20000) throw const FormatException('Notes exceed 20,000 characters. Edit them before adding more photos.');
        setState(() { notesController.text = combined; });
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo notes added. Review and correct the text before generating.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not read photo: $error')),
      );
    } finally {
      if (mounted) setState(() { readingPhoto = false; });
    }
  }

  @override
  void dispose() {
    topicController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> generate() async {
    final topic = topicController.text.trim();
    final notes = notesController.text.trim();
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject name.')),
      );
      return;
    }
    if (useNotes && notes.length < 80) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste at least 80 characters of notes.')),
      );
      return;
    }
    setState(() { generating = true; completed = 0; });
    try {
      final generated = await GeminiQuizService.generate(
        topic: topic,
        count: count,
        notes: useNotes ? notes : null,
        expandOutline: useNotes && expandOutline,
        onProgress: (done, total) {
          if (mounted) setState(() { completed = done; });
        },
      );
      if (!mounted) return;
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Quiz generated!'),
          content: Text('Gemini created ${generated.length} questions for "$topic". '
              'AI can make mistakes. Check the answers against your notes or a trusted source. '
              'Save these questions to your library?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Discard')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save questions')),
          ],
        ),
      );
      if (shouldSave != true || !mounted) return;
      for (final question in generated) {
        await QuizDatabase.instance.addQuestion(question);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${generated.length} questions.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate quiz: $error')),
      );
    } finally {
      if (mounted) setState(() { generating = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Generate with Gemini')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Create an AI revision quiz',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, icon: Icon(Icons.lightbulb_outline),
              label: Text('From topic')),
            ButtonSegment(value: true, icon: Icon(Icons.notes),
              label: Text('From notes')),
          ],
          selected: {useNotes},
          onSelectionChanged: busy ? null : (selection) {
            setState(() { useNotes = selection.first; });
          },
        ),
        const SizedBox(height: 18),
        TextField(
          controller: topicController,
          maxLength: 120,
          enabled: !busy,
          decoration: InputDecoration(
            labelText: useNotes ? 'Subject name' : 'Quiz topic',
            hintText: useNotes ? 'e.g. Week 3 - Networking' : 'e.g. Human anatomy',
            border: const OutlineInputBorder(),
          ),
        ),
        if (useNotes) ...[
          const SizedBox(height: 8),
          const Text('Photos are sent to Google Gemini for transcription. Avoid private or sensitive material.'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: busy ? null : () => readPhotos(ImageSource.camera),
              icon: const Icon(Icons.camera_alt), label: const Text('Take photo')),
            OutlinedButton.icon(onPressed: busy ? null : () => readPhotos(ImageSource.gallery),
              icon: const Icon(Icons.photo_library), label: const Text('Choose photos')),
          ]),
          if (readingPhoto) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const Text('Reading photos with Gemini…'),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: notesController,
            enabled: !busy,
            minLines: 7,
            maxLines: 12,
            maxLength: 20000,
            decoration: const InputDecoration(
              labelText: 'Paste or review revision notes',
              hintText: 'Paste lecture notes or study material here...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Expand revision outline'),
            subtitle: const Text('Use Gemini knowledge to answer topics listed '
                'in revision checklists. Turn off to use only facts in your notes.'),
            value: expandOutline,
            onChanged: busy ? null : (value) {
              setState(() { expandOutline = value; });
            },
          ),
          const Text('Only paste material you are comfortable sending to Gemini. '
            'Your notes are sent to Google for quiz generation, but are not '
            'saved by QuizForge in its question database.'),
        ],
        const SizedBox(height: 12),
        Text('Number of questions: $count',
          style: const TextStyle(fontSize: 18)),
        Slider(
          value: count.toDouble(), min: 1, max: 50, divisions: 49,
          label: '$count',
          onChanged: busy ? null : (value) {
            setState(() { count = value.round(); });
          },
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: busy ? null : generate,
          icon: const Icon(Icons.auto_awesome),
          label: Text(generating ? 'Generating…' : 'Generate $count questions'),
        ),
        if (generating) ...[
          const SizedBox(height: 18),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 8),
          Center(child: Text('Generated $completed of $count questions. '
              'Please wait; large quizzes take longer.')),
        ],
        const SizedBox(height: 20),
        const Text('Requires internet access. AI-generated answers may be inaccurate; '
          'check them before relying on them for revision.'),
      ],
    ),
  );
}
