import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:flutter/material.dart';

class TenantTypeDropdown extends StatelessWidget {
  const TenantTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
  });

  final TenantType? value;
  final ValueChanged<TenantType?> onChanged;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<TenantType>(
      hint: l10n.tenantType,
      value: value,
      isRequired: isRequired,
      items: [
        if (!isRequired) DropdownMenuItem(value: null, child: Text(l10n.tenantType)),
        ...TenantType.values.map(
          (t) => DropdownMenuItem(
            value: t,
            child: Text(t.getLocalizedLabel(l10n)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
