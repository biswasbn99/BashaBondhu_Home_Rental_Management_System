import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LocaleProvider extends ChangeNotifier {
  final String _localeKey ='locale';

  Locale _currentLocale =Locale('en');

  List<Locale> get supportedLocales => [
        Locale('en'),
        Locale('bn'),
      ];
  

  Locale get currentLocale => _currentLocale;
  Locale get locale => _currentLocale;

  void changeLocale(Locale locale){
    _currentLocale = locale;
    _saveCurrentLocale(locale);
    notifyListeners();
  }
  Future<void> init()async{
    await _setCurrentLocale();
  }

  Future<void> _saveCurrentLocale(Locale locale) async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setString(_localeKey, locale.languageCode);
    } catch (e) {
      debugPrint('⚠️ Error saving locale to SharedPreferences: $e');
    }
  }

  Future<void> _setCurrentLocale() async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String? languageCode = sharedPreferences.getString(_localeKey);
      if (languageCode != null) {
        _currentLocale = Locale(languageCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Error loading locale from SharedPreferences: $e');
      _currentLocale = const Locale('en');
    }
  }
  
}