import 'package:flutter/material.dart';
import '../widgets/policy_content_scaffold.dart';

class TermsConditionsScreen extends StatelessWidget {
  static const String name = '/terms-conditions';
  final String targetAudience; // 'tenant' or 'house_owner'

  const TermsConditionsScreen({
    super.key,
    this.targetAudience = 'tenant',
  });

  @override
  Widget build(BuildContext context) {
    return PolicyContentScaffold(
      policyType: 'terms_conditions',
      targetAudience: targetAudience,
      defaultIcon: Icons.gavel_rounded,
    );
  }
}
