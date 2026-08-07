import 'package:flutter/material.dart';
import 'package:bashabondhu_home_rental_management_system/l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext{
    AppLocalizations get localizations => AppLocalizations.of(this)!;
}