part of 'theme_cubit.dart';

class ThemeState extends Equatable {
  final bool isDark;
  final ThemeData themeData;

  ThemeState({this.isDark = true, ThemeData? themeData})
    : themeData = themeData ?? ThemeManager.darkTheme;

  ThemeState copyWith({bool? isDark, ThemeData? themeData}) {
    final bool dark = isDark ?? this.isDark;

    return ThemeState(
      isDark: dark,
      themeData:
          themeData ??
          (dark ? ThemeManager.darkTheme : ThemeManager.lightTheme),
    );
  }

  @override
  List<Object> get props => [isDark, themeData];
}
