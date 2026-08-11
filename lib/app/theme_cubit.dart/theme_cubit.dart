import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/caching/cach_helper.dart';
import '../../core/constants/theme_manager.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState()) {
    _loadTheme();
  }

  void _loadTheme() {
    final bool? isDark = CacheHelper().getData(key: 'isDark');

    if (isDark == true) {
      setDarkTheme(savePreference: false);
    } else {
      setLightTheme(savePreference: false);
    }
  }

  FutureOr<void> setDarkTheme({bool savePreference = true}) async {
    if (savePreference) {
      await CacheHelper().saveData(key: 'isDark', value: true);
    }

    emit(state.copyWith(isDark: true, themeData: ThemeManager.darkTheme));
  }

  FutureOr<void> setLightTheme({bool savePreference = true}) async {
    if (savePreference) {
      await CacheHelper().saveData(key: 'isDark', value: false);
    }

    emit(state.copyWith(isDark: false, themeData: ThemeManager.lightTheme));
  }
}
