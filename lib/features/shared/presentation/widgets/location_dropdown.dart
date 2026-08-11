import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:flutter/material.dart';

import '../../data/models/district_model.dart';
import '../../data/models/division_model.dart';
import '../../data/models/upazila_model.dart';
import 'filter_dropdown.dart';


class DivisionDropdown extends StatelessWidget {
  const DivisionDropdown({
    super.key,
    required this.value,
    required this.divisions,
    required this.onChanged,
    this.isLoading = false,
  });

  final DivisionModel? value;
  final List<DivisionModel> divisions;
  final ValueChanged<DivisionModel?> onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {

    // Division
    return FilterDropdown<DivisionModel>(
      hint: context.localizations.division,
      value: value,
      isLoading: isLoading,
      items: divisions
          .map(
            (division) => DropdownMenuItem(
              value: division,
              child: Text(division.bnName),
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
  });

  final DistrictModel? value;
  final List<DistrictModel> districts;
  final ValueChanged<DistrictModel?> onChanged;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilterDropdown<DistrictModel>(
      hint: context.localizations.district,
      value: value,
      enabled: enabled,
      isLoading: isLoading,
      items: districts
          .map(
            (district) => DropdownMenuItem(
              value: district,
              child: Text(district.bnName),
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
  });

  final UpazilaModel? value;
  final List<UpazilaModel> upazilas;
  final ValueChanged<UpazilaModel?> onChanged;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilterDropdown<UpazilaModel>(
      hint: context.localizations.upazila,
      value: value,
      enabled: enabled,
      isLoading: isLoading,
      items: upazilas
          .map(
            (upazila) => DropdownMenuItem(
              value: upazila,
              child: Text(upazila.bnName),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}