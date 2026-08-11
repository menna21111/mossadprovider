// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

enum LanguageType { ENGLISH, ARABIC, NETHERLANDS }

String language = '';

const String ARABIC = "ar";
const String ENGLISH = "en";
const String Netherlands = "nl";
const String ASSET_PASS_LANGUAGE = "assets/translation";
const Locale ARABIC_LOCALE = Locale("ar", "SA");
const Locale ENGLISH_LOCALE = Locale("en", "US");
const Locale Netherlands_LOCALE = Locale("nl", "NL");

extension LanguageTypeExtension on LanguageType {
  String getValue() {
    switch (this) {
      case LanguageType.ENGLISH:
        return ENGLISH;
      case LanguageType.ARABIC:
        return ARABIC;
      case LanguageType.NETHERLANDS:
        return Netherlands;
    }
  }
}
