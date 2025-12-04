import 'package:flutter/material.dart';
import 'package:todo_app/commons/todo_list_tile.dart';
import 'package:todo_app/models/todo_model.dart';
import 'package:todo_app/provider/to_do_provider.dart';
import 'package:todo_app/screens/todo_input_bottomsheet.dart';
import 'package:provider/provider.dart';

class ToDoHomeScreen extends StatefulWidget {
  const ToDoHomeScreen({super.key});

  @override
  State<ToDoHomeScreen> createState() => ToDoHomeScreenState();
}

class ToDoHomeScreenState extends State<ToDoHomeScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          width: size.width,
          color: Colors.white,
          child: Stack(
            children: [
              Container(
                height: size.height * 0.4,
                width: size.width,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    colors: [Colors.lightBlueAccent, Color(0xff8C72FC)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    "TODO",
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 200,
                left: 22,
                child: Container(
                  height: size.height * 0.7,
                  width: size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Consumer<ToDoProvider>(
                    builder: (_, toDoProvider, __) {
                      return toDoProvider.toDoList.isNotEmpty
                          ? ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: toDoProvider.toDoList.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final task = toDoProvider.toDoList[index];
                              return ToDoListTile(
                                modelData: task,
                                onEdit: () => showToDoInputBottomsheet(task: task),
                                onDelete: () => toDoProvider.deleteToDo(task.id!),
                              );
                            },
                          )
                          : const Center(
                            child: Text(
                              "No TODO's added",
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.black26,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showToDoInputBottomsheet();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void showToDoInputBottomsheet({ToDoModel? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ToDoInputBottomsheet(task: task);
      },
    );
  }
}