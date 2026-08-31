import 'package:flutter/material.dart';
import '../widgets/policy_content_scaffold.dart';

class SupportPolicyScreen extends StatelessWidget {
  static const String name = '/support-policy';
  final String targetAudience; // 'tenant' or 'house_owner'

  const SupportPolicyScreen({
    super.key,
    this.targetAudience = 'tenant',
  });

  @override
  Widget build(BuildContext context) {
    return PolicyContentScaffold(
      policyType: 'support_policy',
      targetAudience: targetAudience,
      defaultIcon: Icons.support_agent_rounded,
    );
  }
}
