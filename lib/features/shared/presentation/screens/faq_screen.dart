import 'package:flutter/material.dart';
import '../widgets/faq_content_view.dart';

class FaqScreen extends StatelessWidget {
  static const String name = '/faq';
  final String targetAudience; // 'tenant', 'house_owner', or 'all'

  const FaqScreen({
    super.key,
    this.targetAudience = 'all',
  });

  @override
  Widget build(BuildContext context) {
    return FaqContentView(targetAudience: targetAudience);
  }
}
