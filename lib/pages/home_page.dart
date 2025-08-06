import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_lisha/global.dart';
import 'package:todo_lisha/pages/task_page.dart';
import 'package:todo_lisha/widgets/task_tile.dart';

int priorityValue(String p) {
  switch (p) {
    case 'high':
      return 3;
    case 'medium':
      return 2;
    case 'low':
      return 1;
    default:
      return 0;
  }
}

Future<Map<String, List<Map<String, dynamic>>>> fetchAndSortTasks() async {
  final prefs = await SharedPreferences.getInstance();
  final taskList = prefs.getStringList('tasks') ?? [];

  final now = DateTime.now();
  List<Map<String, dynamic>> upcoming = [];
  List<Map<String, dynamic>> pastDue = [];
  List<Map<String, dynamic>> completed = [];

  for (String jsonStr in taskList) {
    final task = jsonDecode(jsonStr);
    final dueDate = DateTime.tryParse(task['dueDate'] ?? '');
    final isCompleted = task['completed'] ?? false;
    if (isCompleted) {
      completed.add(task);
    } else if (dueDate != null && dueDate.isBefore(now)) {
      pastDue.add(task);
    } else {
      upcoming.add(task);
    }
  }

  // Sort upcoming: near deadline → far, priority high → low
  upcoming.sort((a, b) {
    final aDate = DateTime.parse(a['dueDate']);
    final bDate = DateTime.parse(b['dueDate']);

    if (aDate.compareTo(bDate) != 0) {
      return aDate.compareTo(bDate);
    }
    return priorityValue(b['priority']).compareTo(priorityValue(a['priority']));
  });

  // Sort pastDue and completed: latest date → older, priority high → low
  int sortByDateAndPriority(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aDate = DateTime.parse(a['dueDate']);
    final bDate = DateTime.parse(b['dueDate']);

    if (bDate.compareTo(aDate) != 0) {
      return bDate.compareTo(aDate);
    }
    return priorityValue(b['priority']).compareTo(priorityValue(a['priority']));
  }

  pastDue.sort(sortByDateAndPriority);
  completed.sort(sortByDateAndPriority);

  return {'upcoming': upcoming, 'pastDue': pastDue, 'completed': completed};
}

Future<void> deleteTask(String taskId) async {
  final prefs = await SharedPreferences.getInstance();

  final taskList = prefs.getStringList('tasks') ?? [];

  final updatedTasks = taskList.where((taskString) {
    final task = jsonDecode(taskString);
    return task['taskId'] != taskId;
  }).toList();

  await prefs.setStringList('tasks', updatedTasks);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    taskSection = upcomingTasks;
    loadTasks();
  }

  List<Map<String, dynamic>> upcomingTasks = [];
  List<Map<String, dynamic>> pastDueTasks = [];
  List<Map<String, dynamic>> completedTasks = [];

  Future<void> loadTasks() async {
    final result = await fetchAndSortTasks();
    setState(() {
      upcomingTasks = result['upcoming']!;
      pastDueTasks = result['pastDue']!;
      completedTasks = result['completed']!;
      taskSection = currentSection == 0
          ? upcomingTasks
          : currentSection == 1
          ? pastDueTasks
          : completedTasks;
    });
  }

  Future<void> updateTaskStatus(String taskId, bool status) async {
    final prefs = await SharedPreferences.getInstance();
    final taskListJson = prefs.getStringList('tasks') ?? [];

    final updatedTasks = taskListJson.map((taskStr) {
      final taskMap = jsonDecode(taskStr);
      if (taskMap['taskId'] == taskId) {
        taskMap['completed'] = status;
      }
      return jsonEncode(taskMap);
    }).toList();

    await prefs.setStringList('tasks', updatedTasks);
    loadTasks();
  }

  int currentSection = 0;
  List<Map<String, dynamic>> taskSection = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "To-Do's",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 25),
          topSection(),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: taskSection.length + 1,
              itemBuilder: (context, index) {
                if (index == taskSection.length) {
                  return SizedBox(height: 80);
                }
                final task = taskSection[index];
                return Dismissible(
                  key: Key(task['taskId']),
                  direction:
                      DismissDirection.endToStart, // Swipe from right to left
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    deleteTask(task['taskId']).then((_) => loadTasks());
                  },
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskPage(
                            taskId: task['taskId'],
                            title: task['title'],
                            description: task['description'] ?? '',
                            dueDate: DateTime.parse(task['dueDate']),
                            priority: Priority.values.firstWhere(
                              (p) => p.name == task['priority'],
                            ),
                            canEdit: false,
                          ),
                        ),
                      ).then((_) => loadTasks());
                    },
                    child: TaskTile(
                      title: task['title'],
                      description: task['description'] ?? '',
                      dueDate: DateTime.parse(task['dueDate']),
                      priority: Priority.values.firstWhere(
                        (p) => p.name == task['priority'],
                      ),
                      isCompleted: task['completed'] ?? false,
                      onChanged: (value) {
                        updateTaskStatus(
                          task['taskId'],
                          value ?? !(task['completed'] ?? false),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskPage()),
          ).then((_) => loadTasks());
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget topSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(100, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
                currentSection = 0;
                taskSection = upcomingTasks;
                setState(() {});
              },
              child: Text("Upcoming", style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 5),
            ColoredBox(
              color: currentSection == 0
                  ? Colors.yellow.shade700
                  : Colors.yellow.shade100,
              child: SizedBox(width: 80, height: 5),
            ),
          ],
        ),
        Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(80, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
                currentSection = 1;
                taskSection = pastDueTasks;
                setState(() {});
              },
              child: Text("Past Due", style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 5),
            ColoredBox(
              color: currentSection == 1
                  ? Colors.red.shade700
                  : Colors.red.shade100,
              child: SizedBox(width: 80, height: 5),
            ),
          ],
        ),
        Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(80, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () {
                currentSection = 2;
                taskSection = completedTasks;
                setState(() {});
              },
              child: Text("Completed", style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 5),
            ColoredBox(
              color: currentSection == 2
                  ? Colors.green.shade900
                  : Colors.green.shade100,
              child: SizedBox(width: 80, height: 5),
            ),
          ],
        ),
      ],
    );
  }
}
