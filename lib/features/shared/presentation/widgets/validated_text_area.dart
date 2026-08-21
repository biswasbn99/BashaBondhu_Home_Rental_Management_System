import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';

class ValidatedTextArea extends StatefulWidget {
  const ValidatedTextArea({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.maxWords,
    this.initialValue = '',
    this.validator,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final int maxWords;
  final String initialValue;
  final String? Function(String?)? validator;

  @override
  State<ValidatedTextArea> createState() => _ValidatedTextAreaState();
}

class _ValidatedTextAreaState extends State<ValidatedTextArea> {
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _wordCount = _countWords(widget.initialValue);
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          initialValue: widget.initialValue,
          maxLines: 5,
          onChanged: (val) {
            setState(() {
              _wordCount = _countWords(val);
            });
            widget.onChanged(val);
          },
          validator: (val) {
            if (_countWords(val ?? '') > widget.maxWords) {
              return 'Max ${widget.maxWords} words allowed';
            }
            return widget.validator?.call(val);
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hint,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$_wordCount / ${widget.maxWords} words',
          style: theme.textTheme.bodySmall?.copyWith(
            color: _wordCount > widget.maxWords ? Colors.red : Colors.grey,
          ),
        ),
      ],
    );
  }
}
