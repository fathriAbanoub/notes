import 'package:flutter/material.dart';

class ToDoTile extends StatelessWidget {
  final String taskName;
  final bool taskCompleted;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? deleteFunction;

  ToDoTile({
    Key? key,
    required this.taskName,
    required this.taskCompleted,
    required this.onChanged,
    required this.deleteFunction,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(taskName),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20.0),
        child: Semantics(
          label: 'Завершить', // 'Complete' in Russian
          child: Icon(
            Icons.done,
            color: Colors.white,
          ),
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.0),
        child: Semantics(
          label: 'Отменить', // 'Undo' in Russian
          child: Icon(
            Icons.close,
            color: Colors.white,
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _toggleCheckboxValue(true);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          _toggleCheckboxValue(false);
          return false;
        }
        return true;
      },
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Semantics(
                value: taskCompleted
                    ? 'Задача выполнена'
                    : 'Задача не выполнена', // 'Task completed' and 'Task not completed' in Russian
                child: Checkbox(
                  value: taskCompleted,
                  onChanged: onChanged,
                ),
              ),
              Expanded(
                child: Text(
                  taskName,
                  style: TextStyle(
                    decoration:
                        taskCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 252, 252, 252),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  void _toggleCheckboxValue(bool? value) {
    if (onChanged != null) {
      onChanged!(value);
    }
  }
}
