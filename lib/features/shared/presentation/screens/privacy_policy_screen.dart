import 'package:flutter/material.dart';
import '../widgets/policy_content_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const String name = '/privacy-policy';
  final String targetAudience; // 'tenant' or 'house_owner'

  const PrivacyPolicyScreen({
    super.key,
    this.targetAudience = 'tenant',
  });

  @override
  Widget build(BuildContext context) {
    return PolicyContentScaffold(
      policyType: 'privacy_policy',
      targetAudience: targetAudience,
      defaultIcon: Icons.privacy_tip_outlined,
    );
  }
}
