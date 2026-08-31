import 'package:flutter/material.dart';
import '../widgets/faq_content_view.dart';

class FaqScreen extends StatelessWidget {
  static const String name = '/faq';

  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FaqContentView();
  }
}
