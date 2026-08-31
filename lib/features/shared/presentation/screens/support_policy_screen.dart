import 'package:flutter/material.dart';
import '../widgets/policy_content_scaffold.dart';

class SupportPolicyScreen extends StatelessWidget {
  static const String name = '/support-policy';

  const SupportPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyContentScaffold(
      policyType: 'support_policy',
      defaultIcon: Icons.support_agent_rounded,
    );
  }
}

