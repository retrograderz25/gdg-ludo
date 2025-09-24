import 'package:flutter/material.dart';

class JoinRoomDialog extends StatefulWidget {
  final void Function(String roomCode) onJoin;

  const JoinRoomDialog({super.key, required this.onJoin});

  @override
  State<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends State<JoinRoomDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tham gia phòng'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(labelText: 'Nhập mã phòng'),
          maxLength: 6,
          validator: (value) {
            if (value == null || value.length < 6) {
              return 'Mã phòng phải có 6 ký tự';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onJoin(_controller.text.toUpperCase());
              Navigator.of(context).pop();
            }
          },
          child: const Text('Tham gia'),
        ),
      ],
    );
  }
}
