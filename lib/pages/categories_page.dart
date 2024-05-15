import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:notes/pages/Tasks_Page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<String> categories = ['Everyday Tasks', 'Travel Plans'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Категории'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: Hive.openBox<String>('categories'),
        builder: (BuildContext context, AsyncSnapshot<Box<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final box = snapshot.data!;
            final categoryList = box.values.toList();
            return ListView.builder(
              itemCount: categoryList.length,
              itemBuilder: (context, index) {
                final category = categoryList[index];

                return Dismissible(
                  key: Key(category),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (direction) {
                    setState(() {
                      categoryList.removeAt(index);
                      box.deleteAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$category dismissed')),
                    );
                  },
                  background: Container(
                    alignment: Alignment.centerLeft,
                    color: Colors.red,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Icon(Icons.delete_forever),
                    ),
                  ),
                  child: Card(
                    child: ListTile(
                      title: Text(category),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CategoryNotes(
                                      category: category,
                                    )));
                        print('Tapped on $category');
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        backgroundColor: Colors.blue,
        child: Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
      ),
    );
  }

  void _addCategory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController categoryController = TextEditingController();
        return AlertDialog(
          title: Text('Добавить новую категорию'),
          content: TextField(
            controller: categoryController,
            decoration: InputDecoration(
              hintText: 'Введите название категории',
            ),
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
                final newCategory = categoryController.text;
                setState(() {
                  categories.add(newCategory);
                });

                addCategory(newCategory); // Save the new category to Hive
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void addCategory(String newCategory) async {
    final box = await Hive.openBox<String>('categories');
    box.add(newCategory);
    setState(() {
      categories.add(newCategory);
    });
  }
}
