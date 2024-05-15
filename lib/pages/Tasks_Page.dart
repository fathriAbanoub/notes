import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:notes/pages/to_do_tile.dart';

class AddNote extends StatefulWidget {
  final Function(String) onNoteAdded;
  AddNote({required this.onNoteAdded});
  @override
  _AddNoteState createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  final TextEditingController _textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('добавить заметку'),
      content: TextField(
        controller: _textEditingController,
        decoration: InputDecoration(hintText: 'Введите свою заметку'),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Отменить'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Добавь'),
          onPressed: () {
            String noteText = _textEditingController.text;
            widget.onNoteAdded(noteText); // Call the callback to add the note
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}

class CategoryNotes extends StatefulWidget {
  final String category;
  CategoryNotes({required this.category});
  @override
  _CategoryNotesState createState() => _CategoryNotesState();
}

class _CategoryNotesState extends State<CategoryNotes> {
  late Future<Box<String>> _categoriesBoxFuture;
  Map<String, bool> taskCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _categoriesBoxFuture = _initHive();
  }

  Future<Box<String>> _initHive() async {
    final appDocumentDir =
        await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    return Hive.openBox<String>(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _categoriesBoxFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final box = snapshot.data!;
            final notesList = box.values.toList();

            return ListView.builder(
              itemCount: notesList.length,
              itemBuilder: (context, index) {
                final note = notesList[index];
                bool taskCompleted = taskCompletionStatus[note] ?? false;

                return Row(
                  children: [
                    Expanded(
                      child: ToDoTile(
                        taskName: note,
                        taskCompleted: taskCompleted,
                        onChanged: (completed) {
                          setState(() {
                            taskCompletionStatus[note] = completed ??
                                false; // Update the visual state of the checkbox
                          });
                        },
                        deleteFunction: (context) async {
                          await box.deleteAt(index);
                          setState(() {
                            taskCompletionStatus.remove(note);
                          }); // Trigger rebuild to update UI
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        _editTask(context, note);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('удалить Заметку'),
                              content: Text(
                                  'Вы уверены, что хотите удалить эту заметку?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Отменить'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await box.deleteAt(index);
                                    setState(() {
                                      taskCompletionStatus.remove(note);
                                    });
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('удалить'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(9.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              label: 'Добавить новую заметку',
              hint: 'Нажмите для добавления задачи',
              button: true,
              child: FloatingActionButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AddNote(
                        onNoteAdded: (note) async {
                          final notesBox = await _categoriesBoxFuture;
                          notesBox.add(note); // Save note to Hive
                          setState(() {
                            taskCompletionStatus[note] =
                                false; // Initialize as not completed
                          }); // Trigger rebuild to update UI
                        },
                      );
                    },
                  );
                },
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _editTask(BuildContext context, String note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController _editingController =
            TextEditingController(text: note);
        return AlertDialog(
          title: Text('изменить Заметку'),
          content: TextField(
            controller: _editingController,
            decoration: InputDecoration(hintText: 'Edit your task'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Отменить'),
            ),
            TextButton(
              onPressed: () async {
                final editedTask = _editingController.text;
                final box = await _categoriesBoxFuture;
                int noteIndex = box.values.toList().indexOf(note);
                await box.putAt(noteIndex, editedTask);
                setState(() {
                  taskCompletionStatus.remove(note);
                  taskCompletionStatus[editedTask] =
                      taskCompletionStatus[note] ?? false;
                });
                Navigator.of(context).pop();
              },
              child: Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}
