import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_kozlov/main.dart';

void main() {
  const draft = Key('new-note');
  const edit = Key('edit-note');

  Finder saveInside(Finder parent) =>
      find.descendant(of: parent, matching: find.text('Сохранить'));

  testWidgets('Validates, adds, edits, and deletes notes', (tester) async {
    await tester.pumpWidget(const NotesApp());

    await tester.enterText(find.byKey(draft), '   ');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Введите текст заметки'), findsOneWidget);
    expect(find.byType(Card), findsNothing);

    for (final text in ['Первая запись', 'Вторая запись']) {
      await tester.enterText(find.byKey(draft), text);
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
    }

    final first = find.ancestor(
      of: find.text('Первая запись'),
      matching: find.byType(Dismissible),
    );
    final openEditor = find.descendant(
      of: first,
      matching: find.byWidgetPredicate(
        (widget) => widget is InkWell && widget.onLongPress != null,
      ),
    );
    await tester.longPress(openEditor);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(edit), '   ');
    await tester.tap(saveInside(find.byType(AlertDialog)));
    await tester.pumpAndSettle();
    expect(find.text('Введите текст заметки'), findsOneWidget);

    await tester.enterText(find.byKey(edit), 'Проверка отмены');
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Первая запись'), findsOneWidget);
    expect(find.text('Проверка отмены'), findsNothing);

    await tester.longPress(openEditor);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(edit), 'Первая запись обновлена');
    await tester.tap(saveInside(find.byType(AlertDialog)));
    await tester.pumpAndSettle();
    expect(find.text('Первая запись'), findsNothing);
    expect(find.text('Первая запись обновлена'), findsOneWidget);

    final updated = find.ancestor(
      of: find.text('Первая запись обновлена'),
      matching: find.byType(Dismissible),
    );
    await tester.drag(updated, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.text('Первая запись обновлена'), findsNothing);
    expect(find.text('Вторая запись'), findsOneWidget);
  });

  testWidgets('All five gestures act on the selected note', (tester) async {
    await tester.pumpWidget(const NotesApp());
    const original = 'Первая строка\nВторая строка\nПолный текст заметки';
    const updated = 'Заметка после редактирования';
    final note = find.byType(Dismissible);
    final noteText = find.descendant(of: note, matching: find.byType(Text));
    final star = find.byIcon(Icons.star_rounded);

    await tester.enterText(find.byKey(draft), original);
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    await tester.tap(noteText);
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
    expect(find.text('Просмотр заметки'), findsOneWidget);
    expect(
      tester.widget<SelectableText>(find.byType(SelectableText)).data,
      original,
    );
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();

    await tester.tap(noteText);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(noteText);
    await tester.pumpAndSettle();
    expect(star, findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.longPress(noteText);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(edit), updated);
    await tester.tap(saveInside(find.byType(AlertDialog)));
    await tester.pumpAndSettle();
    expect(find.text(updated), findsOneWidget);
    expect(star, findsOneWidget);

    await tester.drag(note, const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(star, findsNothing);
    expect(note, findsOneWidget);

    await tester.drag(note, const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(note, findsOneWidget);

    await tester.drag(note, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(note, findsNothing);
  });
}
