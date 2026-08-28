import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

extension UtilityExtension on BuildContext {
  AppLocalizations get localizations => AppLocalizations.of(this)!;

  TextTheme get textTheme => TextTheme.of(this);
}

extension MonthLocalizationExtension on String {
  String getLocalizedMonth(AppLocalizations l10n) {
    switch (toLowerCase().trim()) {
      case 'january':
        return l10n.january;
      case 'february':
        return l10n.february;
      case 'march':
        return l10n.march;
      case 'april':
        return l10n.april;
      case 'may':
        return l10n.may;
      case 'june':
        return l10n.june;
      case 'july':
        return l10n.july;
      case 'august':
        return l10n.august;
      case 'september':
        return l10n.september;
      case 'october':
        return l10n.october;
      case 'november':
        return l10n.november;
      case 'december':
        return l10n.december;
      default:
        return this;
    }
  }
}

extension RoomOrSeatLocalizationExtension on String {
  String getLocalizedRoomOrSeat(AppLocalizations l10n) {
    if (trim().isEmpty) return this;
    final isBn = l10n.localeName == 'bn';

    String convertDigits(String str, bool toBn) {
      const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      var res = str;
      if (toBn) {
        for (int i = 0; i < 10; i++) {
          res = res.replaceAll(enDigits[i], bnDigits[i]);
        }
      } else {
        for (int i = 0; i < 10; i++) {
          res = res.replaceAll(bnDigits[i], enDigits[i]);
        }
      }
      return res;
    }

    final lower = toLowerCase().trim();

    // Extract any number (English or Bengali digits)
    final match = RegExp(r'[0-9০-৯]+').firstMatch(this);
    final numberStr = match?.group(0) ?? '';
    final localizedNumber = convertDigits(numberStr, isBn);

    if (lower.contains('bedroom') || lower.contains('বেডরুম')) {
      return localizedNumber.isNotEmpty
          ? '${l10n.bedroom} - $localizedNumber'
          : l10n.bedroom;
    } else if (lower.contains('empty seat') || lower.contains('seat') || lower.contains('সিট')) {
      return localizedNumber.isNotEmpty
          ? '${l10n.emptySeat} - $localizedNumber'
          : l10n.emptySeat;
    } else if (lower.contains('unit') || lower.contains('ইউনিট')) {
      return localizedNumber.isNotEmpty
          ? '${l10n.unit} - $localizedNumber'
          : l10n.unit;
    } else if (lower.contains('room') || lower.contains('রুম')) {
      return localizedNumber.isNotEmpty
          ? '${l10n.room} - $localizedNumber'
          : l10n.room;
    }

    return convertDigits(this, isBn);
  }
}

extension NumberLocalizationExtension on num {
  String toLocalizedDigits(String languageCode) {
    if (languageCode != 'bn') return toString();
    const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var res = toString();
    for (int i = 0; i < 10; i++) {
      res = res.replaceAll(enDigits[i], bnDigits[i]);
    }
    return res;
  }
}

extension StringNumberLocalizationExtension on String {
  String toLocalizedDigits(String languageCode) {
    if (languageCode != 'bn') return this;
    const enDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var res = this;
    for (int i = 0; i < 10; i++) {
      res = res.replaceAll(enDigits[i], bnDigits[i]);
    }
    return res;
  }
}