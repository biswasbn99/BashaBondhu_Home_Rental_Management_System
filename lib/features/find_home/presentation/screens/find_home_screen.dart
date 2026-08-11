import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/find_home/presentation/providers/find_home_provider.dart';
import 'package:bashabondhu_home_rental_management_system/features/find_home/presentation/screens/search_result.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/filter_dropdown.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/presentation/widgets/location_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



class FindHomeScreen extends StatelessWidget {
  const FindHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final provider = FindHomeProvider();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadDivisions(ctx.localizations);
        });
        return provider;
      },
      child: const _FindHomeView(),
    );
  }
}

class _FindHomeView extends StatelessWidget {
  const _FindHomeView();

  static const Color _teal = Color(0xFF049A8F);
  static const Color _grey = Color(0xFF7A8A88);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FindHomeProvider>();
    final l10n = context.localizations;

    return Scaffold(
      backgroundColor: Colors.white,
      
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.errorMessage != null) ...[
                _ErrorBanner(message: provider.errorMessage!),
                const SizedBox(height: 12),
              ],

              // -------- Month + House type --------
             _SectionLabel(
                title: l10n.accommodationPromptTitle,
                subtitle: l10n.accommodationPromptSubTitle,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilterDropdown<String>(
                      hint: l10n.month,
                      value: provider.selectedMonth,
                      items: FindHomeProvider.months
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: provider.selectMonth,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilterDropdown<HouseType>(
                      hint: l10n.houseType,
                      value: provider.selectedHouseType,
                      items: FindHomeProvider.houseTypes
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.bnLabel),
                            ),
                          )
                          .toList(),
                      onChanged: provider.selectHouseType,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // -------- Location --------
              _SectionLabel(
                title: l10n.locationPromptTitle,
                subtitle: l10n.locationPromptSubTitle,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DivisionDropdown(
                      value: provider.selectedDivision,
                      divisions: provider.divisions,
                      isLoading: provider.isLoadingDivisions,
                      onChanged: (val) => provider.selectDivision(val, l10n),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DistrictDropdown(
                      value: provider.selectedDistrict,
                      districts: provider.districts,
                      enabled: provider.selectedDivision != null,
                      isLoading: provider.isLoadingDistricts,
                      onChanged: (val) => provider.selectDistrict(val, l10n),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              UpazilaDropdown(
                value: provider.selectedUpazila,
                upazilas: provider.upazilas,
                enabled: provider.selectedDistrict != null,
                isLoading: provider.isLoadingUpazilas,
                onChanged: provider.selectUpazila,
              ),

              const SizedBox(height: 12),

              // -------- Room / Seat count --------
              FilterDropdown<String>(
                hint: provider.roomOrSeatHint(l10n),
                value: provider.selectedRoomOrSeat,
                enabled: provider.selectedHouseType != null,
                items: provider.roomOrSeatOptions(l10n)
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: provider.selectRoomOrSeat,
              ),

              const SizedBox(height: 14),
              const Text(
                'উপরের সকল তথ্য সিলেক্ট করা হলে এবার বাসা খুঁজুন বাটনে ক্লিক করুন',
                style: TextStyle(color: _grey, fontSize: 13.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isSearchValid ? () => _search(context, provider) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'বাসা খুঁজুন',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
    );
  }

 
 

  void _search(BuildContext context, FindHomeProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultScreen(filter: provider.buildFilter()),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14.5, color: Color(0xFF6B7280)),
        children: [
          TextSpan(text: '$title '),
          TextSpan(text: subtitle),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAEA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFB3261E), fontSize: 13),
      ),
    );
  }
}