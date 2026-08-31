import 'package:flutter/material.dart';
import '../widgets/policy_content_scaffold.dart';

class RefundPolicyScreen extends StatelessWidget {
  static const String name = '/refund-policy';

  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyContentScaffold(
      policyType: 'refund_policy',
      defaultIcon: Icons.replay_rounded,
    );
  }
}

