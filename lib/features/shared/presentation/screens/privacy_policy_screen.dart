import 'package:flutter/material.dart';
import '../widgets/policy_content_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const String name = '/privacy-policy';

  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyContentScaffold(
      policyType: 'privacy_policy',
      defaultIcon: Icons.privacy_tip_outlined,
    );
  }
}

