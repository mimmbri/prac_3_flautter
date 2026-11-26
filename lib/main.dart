import 'package:flutter/material.dart';

void main() => runApp(const NotesApp());

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Заметки',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xff9e9bff),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xff15161a),
      splashFactory: InkRipple.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff1d1e24),
        contentPadding: const EdgeInsets.all(18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: const NotesPage(),
  );
}

class Note {
  Note(this.text);
  String text;
  bool isImportant = false;
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _form = GlobalKey<FormState>();
  final _draft = TextEditingController();
  final _notes = <Note>[];

  String? _validate(String? text) =>
      (text ?? '').trim().isEmpty ? 'Введите текст заметки' : null;

  void _addNote() {
    if (!_form.currentState!.validate()) return;
    setState(() => _notes.insert(0, Note(_draft.text.trim())));
    _draft.clear();
    FocusScope.of(context).unfocus();
  }

  void _deleteNote(Note note) => setState(() => _notes.remove(note));

  void _viewNote(Note note) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Просмотр заметки'),
        scrollable: true,
        constraints: const BoxConstraints(maxWidth: 428),
        content: SelectableText(note.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(Note note) async {
    final form = GlobalKey<FormState>();
    var draft = note.text;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Редактировать заметку'),
        scrollable: true,
        constraints: const BoxConstraints(maxWidth: 428),
        content: Form(
          key: form,
          child: _noteField(note: note, onChanged: (value) => draft = value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, draft.trim());
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (mounted && result != null && _notes.contains(note)) {
      setState(() => note.text = result);
    }
  }

  Widget _noteField({Note? note, ValueChanged<String>? onChanged}) =>
      TextFormField(
        key: Key(note == null ? 'new-note' : 'edit-note'),
        controller: note == null ? _draft : null,
        initialValue: note?.text,
        validator: _validate,
        onChanged: onChanged,
        minLines: 3,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: note == null ? null : 'Текст заметки',
          hintText: note == null ? 'Напишите заметку…' : null,
          alignLabelWithHint: true,
        ),
      );

  Widget _noteCard(Note note) => Dismissible(
    key: ObjectKey(note),
    direction: note.isImportant
        ? DismissDirection.horizontal
        : DismissDirection.endToStart,
    confirmDismiss: (direction) async {
      if (direction == DismissDirection.endToStart) return true;
      setState(() => note.isImportant = false);
      return false;
    },
    onDismissed: (_) => _deleteNote(note),
    child: Card.filled(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xff1f2026),
      child: InkWell(
        onTap: () => _viewNote(note),
        onDoubleTap: () => setState(() => note.isImportant = true),
        onLongPress: () => _editNote(note),
        child: ListTile(
          trailing: note.isImportant
              ? const Icon(Icons.star_rounded, semanticLabel: 'Важная заметка')
              : null,
          title: Text(note.text, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 640,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text('Заметки', style: theme.textTheme.displaySmall),
                const SizedBox(height: 24),
                Form(key: _form, child: _noteField()),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _addNote,
                    child: const Text('Сохранить'),
                  ),
                ),
                const SizedBox(height: 28),
                for (final note in _notes) _noteCard(note),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
