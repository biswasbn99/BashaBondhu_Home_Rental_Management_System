import 'package:flutter/material.dart';
import '../widgets/policy_content_scaffold.dart';

class TermsConditionsScreen extends StatelessWidget {
  static const String name = '/terms-conditions';

  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyContentScaffold(
      policyType: 'terms_conditions',
      defaultIcon: Icons.gavel_rounded,
    );
  }
}

