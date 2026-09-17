import 'package:bashabondhu_home_rental_management_system/app/app_colors.dart';
import 'package:flutter/material.dart';

class ValidatedTextArea extends StatefulWidget {
  const ValidatedTextArea({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.maxWords,
    this.initialValue = '',
    this.validator,
    this.focusNode,
    this.minLines = 4,
    this.maxLines,
    this.showErrors = false,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final int maxWords;
  final String initialValue;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final int minLines;
  final int? maxLines;
  final bool showErrors;

  @override
  State<ValidatedTextArea> createState() => _ValidatedTextAreaState();
}

class _ValidatedTextAreaState extends State<ValidatedTextArea> {
  late final TextEditingController _controller;
  late final ValueNotifier<int> _wordCountNotifier;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _wordCountNotifier = ValueNotifier<int>(_countWords(widget.initialValue));
  }

  @override
  void didUpdateWidget(covariant ValidatedTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.initialValue != _controller.text) {
          _controller.text = widget.initialValue;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
          _wordCountNotifier.value = _countWords(widget.initialValue);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _wordCountNotifier.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: widget.focusNode,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          scrollPadding: const EdgeInsets.only(bottom: 80),
          onChanged: (val) {
            _wordCountNotifier.value = _countWords(val);
            widget.onChanged(val);
          },
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return isBn
                  ? 'দয়া করে ${widget.hint} লিখুন'
                  : 'Please enter ${widget.hint}';
            }
            if (_countWords(val) > widget.maxWords) {
              return isBn
                  ? 'সর্বোচ্চ ${widget.maxWords} শব্দ লেখা যাবে'
                  : 'Max ${widget.maxWords} words allowed';
            }
            return widget.validator?.call(val);
          },
          autovalidateMode: widget.showErrors
              ? AutovalidateMode.always
              : AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: widget.hint,
            alignLabelWithHint: true,
            filled: true,
            fillColor: theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: theme.brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.themeColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder<int>(
          valueListenable: _wordCountNotifier,
          builder: (context, count, child) {
            return Text(
              isBn
                  ? '$count / ${widget.maxWords} শব্দ'
                  : '$count / ${widget.maxWords} words',
              style: theme.textTheme.bodySmall?.copyWith(
                color: count > widget.maxWords ? Colors.red : Colors.grey,
              ),
            );
          },
        ),
      ],
    );
  }
}
