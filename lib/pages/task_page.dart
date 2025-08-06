import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_lisha/global.dart';
import 'package:uuid/uuid.dart';

class TaskPage extends StatefulWidget {
  final String? taskId;
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final Priority? priority;
  final bool canEdit;

  const TaskPage({
    super.key,
    this.taskId,
    this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.canEdit = true,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late String taskId;
  late bool isEditable;
  bool isSaving = false;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  Priority _selectedPriority = Priority.medium;

  @override
  void initState() {
    super.initState();

    taskId = widget.taskId ?? const Uuid().v4();
    isEditable = widget.canEdit;

    _titleController.text = widget.title ?? '';
    _descController.text = widget.description ?? '';
    _selectedDate = widget.dueDate ?? DateTime.now();
    _selectedPriority = widget.priority ?? Priority.medium;
  }

  void toggleEditMode() {
    setState(() {
      isEditable = !isEditable;
    });
  }

  Future<void> saveTask() async {
    if (isSaving) return;

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Title can't be empty")));
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Due date must be selected")),
      );
      return;
    }
    isSaving = true;
    setState(() {});

    final task = {
      'taskId': taskId,
      'title': title,
      'description': desc,
      'dueDate': _selectedDate!.toIso8601String(),
      'priority': _selectedPriority.name,
      'completed': false,
    };

    final prefs = await SharedPreferences.getInstance();
    final taskList = prefs.getStringList('tasks') ?? [];

    // Check if task already exists → Update
    final index = taskList.indexWhere((t) {
      final map = jsonDecode(t);
      return map['taskId'] == taskId;
    });

    if (index != -1) {
      taskList[index] = jsonEncode(task); // Update
    } else {
      taskList.add(jsonEncode(task)); // New
    }

    await prefs.setStringList('tasks', taskList);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Task saved successfully!")));

    Navigator.pop(context); // or pass back data
  }

  void _pickDate() async {
    if (!isEditable) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Color getPriorityColor(Priority p) {
    switch (p) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final blue = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        leadingWidth: 40,
        title: Text(
          widget.taskId == null ? 'New Task' : 'Task Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: blue,
        actions: [
          if (widget.taskId != null)
            IconButton(
              icon: Icon(
                isEditable ? Icons.visibility : Icons.edit,
                color: Colors.white,
              ),
              tooltip: isEditable ? 'View Mode' : 'Edit Mode',
              onPressed: toggleEditMode,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInputCard(
                    child: TextField(
                      controller: _titleController,
                      maxLength: 80,
                      enabled: isEditable,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    child: TextField(
                      controller: _descController,
                      maxLength: 800,
                      enabled: isEditable,
                      minLines: 4,
                      maxLines: 6,
                      style: const TextStyle(fontWeight: FontWeight.w400),
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Due Date'),
                      subtitle: Text(
                        "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                        style: const TextStyle(fontSize: 15),
                      ),
                      trailing: isEditable
                          ? IconButton(
                              icon: const Icon(Icons.edit_calendar),
                              onPressed: _pickDate,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInputCard(
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined),
                        const SizedBox(width: 12),
                        const Text("Priority"),
                        const Spacer(),
                        DropdownButton<Priority>(
                          value: _selectedPriority,
                          items: Priority.values.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: getPriorityColor(p),
                                    radius: 5,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(p.name.toUpperCase()),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: isEditable
                              ? (value) =>
                                    setState(() => _selectedPriority = value!)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isEditable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ElevatedButton.icon(
                onPressed: saveTask,
                icon: const Icon(Icons.save),
                label: isSaving
                    ? const CircularProgressIndicator()
                    : const Text("Save Task"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
