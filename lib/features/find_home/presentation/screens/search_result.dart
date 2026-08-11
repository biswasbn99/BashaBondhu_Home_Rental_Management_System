import 'package:bashabondhu_home_rental_management_system/app/extensions/utility_extension.dart';
import 'package:bashabondhu_home_rental_management_system/features/shared/data/models/search_filter_model.dart';
import 'package:flutter/material.dart';

class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({super.key, required this.filter});

  final SearchFilterModel filter;

  static const Color _teal = Color(0xFF049A8F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বাসার ফলাফল'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'আপনার অনুসন্ধান',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _row(context.localizations.month, filter.month),
            _row(context.localizations.houseType, filter.houseType.bnLabel),
            _row(context.localizations.division, filter.division.bnName),
            _row(context.localizations.district, filter.district.bnName),
            _row(context.localizations.upazila, filter.upazila.bnName),
            _row(context.localizations.roomOrSeat, filter.roomOrSeat),
           
            const SizedBox(height: 30),
            const Expanded(
              child: Center(
                child: Text(
                  'এই ফিল্টার অনুযায়ী পোস্টগুলো এখানে দেখানো হবে।',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}