import 'package:flutter/material.dart';
import 'package:todo_lisha/global.dart';

class TaskTile extends StatefulWidget {
  final String title;
  final String description;
  final DateTime dueDate;
  final Priority priority;
  final bool isCompleted;
  final ValueChanged<bool?> onChanged;
  const TaskTile({
    super.key,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool? checkTask;

  Color getPriorityColor() {
    switch (widget.priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
    }
  }

  String getPriorityText() {
    switch (widget.priority) {
      case Priority.low:
        return "Low";
      case Priority.medium:
        return "Medium";
      case Priority.high:
        return "High";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Colored Priority Dot
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: getPriorityColor(),
                shape: BoxShape.circle,
              ),
            ),
            // Task Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      decoration: widget.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      decoration: widget.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.dueDate.day}/${widget.dueDate.month}/${widget.dueDate.year}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        getPriorityText(),
                        style: TextStyle(
                          color: getPriorityColor(),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Checkbox
            Checkbox(
              value: checkTask ?? widget.isCompleted,
              onChanged: (val) {
                setState(() {
                  checkTask = !widget.isCompleted;
                });
                Future.delayed(const Duration(milliseconds: 600), () {
                  setState(() {
                    checkTask = null;
                  });
                  widget.onChanged(val);
                });
              },
              activeColor: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}
