import 'package:flutter/material.dart';
import '../widgets/policy_content_scaffold.dart';

class RefundPolicyScreen extends StatelessWidget {
  static const String name = '/refund-policy';
  final String targetAudience; // 'tenant' or 'house_owner'

  const RefundPolicyScreen({
    super.key,
    this.targetAudience = 'tenant',
  });

  @override
  Widget build(BuildContext context) {
    return PolicyContentScaffold(
      policyType: 'refund_policy',
      targetAudience: targetAudience,
      defaultIcon: Icons.replay_rounded,
    );
  }
}
