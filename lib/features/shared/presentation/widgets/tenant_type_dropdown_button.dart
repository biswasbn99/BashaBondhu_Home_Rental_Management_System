import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:flutter/material.dart';
import 'filter_dropdown.dart';

class TenantTypeDropdown extends StatelessWidget {
  const TenantTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TenantType? value;
  final ValueChanged<TenantType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return FilterDropdown<TenantType>(
      hint: l10n.tenantType,
      value: value,
      isRequired: false,
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.tenantType)),
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
