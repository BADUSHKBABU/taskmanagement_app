import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/domain/entity/taskentity.dart';
import 'package:test1/presentation/bloc/taskbloc/task_bloc.dart';
import 'package:test1/presentation/bloc/taskbloc/task_event.dart';
import 'package:test1/presentation/bloc/taskbloc/task_state.dart';

class AddTaskScreen extends StatefulWidget {
  final TaskEntity? task;

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late String _priority;
  late String _category;
  late String _status;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? "Medium";
    _category = t?.category ?? "Work";
    _dueDate = t?.dueDate;

    if (t != null) {
      if (t.isCompleted) {
        _status = "Completed";
      } else if (t.priority == "High") {
        _status = "Started";
      } else {
        _status = "Pending";
      }
      
    } else {
      _status = "Pending";
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.task != null;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Task" : "Add Task"),
        actions: [
          TextButton(
            onPressed: () => _onSave(uid),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Title is required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                dropdownColor: colorScheme.surface,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: const InputDecoration(labelText: "Status"),
                items: ["Pending", "Completed", "Started"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _status = v;
                      if (v == "Started") {
                        _priority = "High";
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      dropdownColor: colorScheme.surface,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: const InputDecoration(labelText: "Priority"),
                      items: ["High", "Medium", "Low"]
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _priority = v;
                            if (v == "High" && _status != "Completed") {
                              _status = "Starred";
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      dropdownColor: colorScheme.surface,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: const InputDecoration(
                        labelText: "Category",
                      ),
                      items: ["Work", "Personal", "Health", "Finance", "Education", "Shopping", "Travel", "Others"]
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(Icons.calendar_today_outlined, color: colorScheme.primary),
                  title: Text(
                    _dueDate == null
                        ? "Select Due Date"
                        : "Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _onSave(String uid) {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a due date")),
      );
      return;
    }

    final isCompleted = (_status == "Completed");
    final priority = (_status == "Starred" ? "High" : _priority);

    if (isEditing) {
      final changes = <String, dynamic>{
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "priority": priority,
        "category": _category,
        "is_completed": isCompleted,
        "due_date": _dueDate!.toIso8601String(),
      };
      context.read<TaskBloc>().add(
            UpdateTaskEvent(
              userId: uid,
              taskId: widget.task!.id!,
              changes: changes,
            ),
          );
    } else {
      final newTask = TaskEntity(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: priority,
        category: _category,
        dueDate: _dueDate!,
        isCompleted: isCompleted,
      );

      context.read<TaskBloc>().add(AddTaskEvent(userId: uid, task: newTask));
    }

    Navigator.pop(context);
  }
}