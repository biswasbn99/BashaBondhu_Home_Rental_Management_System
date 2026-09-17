import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';

import '../../data/models/district_model.dart';
import '../../data/models/division_model.dart';
import '../../data/models/area_model.dart';
import '../../data/models/sub_area_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';


class DivisionDropdown extends StatelessWidget {
  const DivisionDropdown({
    super.key,
    required this.value,
    required this.divisions,
    required this.onChanged,
    this.isLoading = false,
    this.showErrors = false,
  });

  final DivisionModel? value;
  final List<DivisionModel> divisions;
  final ValueChanged<DivisionModel?> onChanged;
  final bool isLoading;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return FilterDropdown<DivisionModel>(
      hint: context.localizations.division,
      value: value,
      isLoading: isLoading,
      showErrors: showErrors,
      items: divisions
          .map(
            (division) => DropdownMenuItem(
              value: division,
              child: Text(division.getLocalizedName(languageCode)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class DistrictDropdown extends StatelessWidget {
  const DistrictDropdown({
    super.key,
    required this.value,
    required this.districts,
    required this.onChanged,
    required this.enabled,
    this.isLoading = false,
    this.showErrors = false,
    this.validator,
  });

  final DistrictModel? value;
  final List<DistrictModel> districts;
  final ValueChanged<DistrictModel?> onChanged;
  final bool enabled;
  final bool isLoading;
  final bool showErrors;
  final String? Function(DistrictModel?)? validator;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return FilterDropdown<DistrictModel>(
      hint: context.localizations.district,
      value: value,
      enabled: enabled,
      isLoading: isLoading,
      showErrors: showErrors,
      validator: validator ??
          (val) {
            if (val == null) {
              if (!enabled) {
                return languageCode == 'bn'
                    ? 'প্রথমে বিভাগ নির্বাচন করুন'
                    : 'Please select division first';
              }
              return languageCode == 'bn'
                  ? 'দয়া করে জেলা নির্বাচন করুন'
                  : 'Please select district';
            }
            return null;
          },
      items: districts
          .map(
            (district) => DropdownMenuItem(
              value: district,
              child: Text(district.getLocalizedName(languageCode)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}


class UpazilaDropdown extends StatelessWidget {
  const UpazilaDropdown({
    super.key,
    required this.value,
    required this.upazilas,
    required this.onChanged,
    required this.enabled,
    this.isLoading = false,
    this.showErrors = false,
    this.validator,
  });

  final UpazilaModel? value;
  final List<UpazilaModel> upazilas;
  final ValueChanged<UpazilaModel?> onChanged;
  final bool enabled;
  final bool isLoading;
  final bool showErrors;
  final String? Function(UpazilaModel?)? validator;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return FilterDropdown<UpazilaModel>(
      hint: context.localizations.upazila,
      value: value,
      enabled: enabled,
      isLoading: isLoading,
      showErrors: showErrors,
      validator: validator ??
          (val) {
            if (val == null) {
              if (!enabled) {
                return languageCode == 'bn'
                    ? 'প্রথমে জেলা নির্বাচন করুন'
                    : 'Please select district first';
              }
              return languageCode == 'bn'
                  ? 'দয়া করে এলাকা নির্বাচন করুন'
                  : 'Please select area';
            }
            return null;
          },
      items: upazilas
          .map(
            (upazila) => DropdownMenuItem(
              value: upazila,
              child: Text(upazila.getLocalizedName(languageCode)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class AreaDropdown extends StatelessWidget {
  const AreaDropdown({
    super.key,
    required this.value,
    required this.areas,
    required this.onChanged,
    required this.enabled,
    this.isLoading = false,
    this.isRequired = false,
    this.showErrors = false,
    this.validator,
  });

  final UnionModel? value;
  final List<UnionModel> areas;
  final ValueChanged<UnionModel?> onChanged;
  final bool enabled;
  final bool isLoading;
  final bool isRequired;
  final bool showErrors;
  final String? Function(UnionModel?)? validator;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return FilterDropdown<UnionModel>(
      hint: context.localizations.area,
      value: value,
      enabled: enabled,
      isLoading: isLoading,
      isRequired: isRequired,
      showErrors: showErrors,
      validator: validator ??
          (val) {
            if (isRequired && val == null) {
              if (!enabled) {
                return languageCode == 'bn'
                    ? 'প্রথমে এলাকা নির্বাচন করুন'
                    : 'Please select area first';
              }
              return languageCode == 'bn'
                  ? 'দয়া করে উপ-এলাকা নির্বাচন করুন'
                  : 'Please select sub-area';
            }
            return null;
          },
      items: areas
          .map(
            (area) => DropdownMenuItem(
              value: area,
              child: Text(area.getLocalizedName(languageCode)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
