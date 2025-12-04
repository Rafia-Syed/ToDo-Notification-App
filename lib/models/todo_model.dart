import 'package:intl/intl.dart';

class ToDoModel {
  int? id;
  String title;
  String description;
  int dateTime; // ✅ store timestamp (millisecondsSinceEpoch)
  bool done;
  ToDoModel(
      {this.id,required this.dateTime, required this.description, required this.title, required this.done});

    // Convert a ToDoModel into a Map.
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'title': title,
      'description': description,
      'dateTime': dateTime,
      'done': done ? 1 : 0, // Convert bool to int
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // Extract a ToDoModel from a Map.
  factory ToDoModel.fromMap(Map<String, dynamic> map) {
  int parsedDate;

  if (map['dateTime'] is int) {
    parsedDate = map['dateTime'];
  } else if (map['dateTime'] is String) {
    // Try parsing string date
    try {
      parsedDate = DateFormat('dd-MM-yy').parse(map['dateTime']).millisecondsSinceEpoch;
    } catch (e) {
      parsedDate = DateTime.now().millisecondsSinceEpoch; // fallback
    }
  } else {
    parsedDate = DateTime.now().millisecondsSinceEpoch;
  }

  return ToDoModel(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    dateTime: parsedDate,
    done: map['done'] == 1, // Convert int to bool
  );
}

  String get formattedDate =>
      DateFormat('dd-MM-yy HH:mm')
          .format(DateTime.fromMillisecondsSinceEpoch(dateTime));
}

