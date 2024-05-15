import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:notes/pages/categories_page.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import './to_do_tile.dart';

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

class HomePage extends StatefulWidget {
  final String nots;
  HomePage({required this.nots});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Box<String>> _notesBoxFuture;
  Map<String, bool> taskCompletionStatus = {};

  @override
  void initState() {
    super.initState();
    _notesBoxFuture = _initHive();
  }

  Future<Box<String>> _initHive() async {
    final appDocumentDir =
        await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);
    return Hive.openBox<String>(widget.nots);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minimalist To_Do App'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _notesBoxFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final box = snapshot.data!;
            final taskList = box.values.toList();
            return ListView.builder(
              itemCount: taskList.length,
              itemBuilder: (context, index) {
                final note = taskList[index];
                // Retrieve the completion status from Hive for the task
                bool taskCompleted = taskCompletionStatus[note] ?? false;
                // Placeholder, replace with actual value from Hive
                // Retrieve completion status from Hive and update taskCompleted
                return Row(
                  children: [
                    Expanded(
                      child: ToDoTile(
                        taskName: note,
                        taskCompleted: taskCompleted,
                        onChanged: (completed) {
                          setState(() {
                            taskCompletionStatus[note] = completed ?? false;
                          });
                        },
                        deleteFunction: (context) async {
                          await box.deleteAt(index);
                          setState(() {
                            taskCompletionStatus.remove(note);
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.redAccent,
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
                            builder: ((context) {
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
                            }));
                      },
                    )
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
              label: 'главная страница',
              hint: 'Нажмите для перехода на главную страницу',
              button: true,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CategoriesPage()));
                },
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                ),
              ),
            ),
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
                          final notesBox = await _notesBoxFuture;
                          notesBox.add(note); // Save note to Hive
                          setState(() {}); // Trigger rebuild to update UI
                        },
                      );
                    },
                  );
                },
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.add,
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
                final box = await _notesBoxFuture;
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
