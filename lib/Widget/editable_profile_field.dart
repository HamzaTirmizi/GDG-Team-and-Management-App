import 'package:flutter/material.dart';

class EditableProfileField extends StatefulWidget {
  final String title;
  final String initialValue;
  final IconData icon;
  final Function(String) onSave;
  final bool isEditable;

  const EditableProfileField({
    super.key,
    required this.title,
    required this.initialValue,
    required this.icon,
    required this.onSave,
    this.isEditable = true,
  });

  @override
  State<EditableProfileField> createState() => _EditableProfileFieldState();
}

class _EditableProfileFieldState extends State<EditableProfileField> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(EditableProfileField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Save
      widget.onSave(_controller.text.trim());
      setState(() => _isEditing = false);
    } else {
      // Start editing
      setState(() => _isEditing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    return Card(
      color: const Color(0xFF151A1E),
      child: Padding(
        padding: EdgeInsets.all(screenwidth * 0.04),
        child: _isEditing
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon, color: const Color(0xFF19D99F)),
                      SizedBox(width: screenwidth * 0.03),
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _toggleEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          _controller.text = widget.initialValue;
                          setState(() => _isEditing = false);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: screenwidth * 0.02),
                  // Use EXACT same TextField style as login/signup pages
                  TextField(
                    controller: _controller,
                    style: TextStyle(fontSize: screenwidth * 0.040),
                    decoration: InputDecoration(
                      hintText: 'Enter ${widget.title.toLowerCase()}',
                      hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                      border: Theme.of(context).inputDecorationTheme.border,
                      focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                      enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenheight * 0.02,
                        horizontal: screenwidth * 0.03,
                      ),
                    ),
                  ),
                ],
              )
            : ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(widget.icon, color: const Color(0xFF19D99F)),
                title: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                subtitle: Text(
                  _controller.text.isEmpty ? 'N/A' : _controller.text,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                trailing: widget.isEditable
                    ? IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF19D99F)),
                        onPressed: _toggleEdit,
                      )
                    : null,
              ),
      ),
    );
  }
}
