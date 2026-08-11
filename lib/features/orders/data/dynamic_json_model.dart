/// Flexible JSON helpers until provider API shapes are finalized.
class DynamicJsonModel {
  const DynamicJsonModel(this.raw);

  final Map<String, dynamic> raw;

  factory DynamicJsonModel.fromJson(Map<String, dynamic> json) {
    return DynamicJsonModel(Map<String, dynamic>.from(json));
  }

  dynamic operator [](String key) => raw[key];

  String string(
    String key, {
    List<String> fallbacks = const [],
    String defaultValue = '',
  }) {
    for (final k in [key, ...fallbacks]) {
      final value = raw[k];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return defaultValue;
  }

  Map<String, dynamic>? map(String key) {
    final value = raw[key];
    return value is Map<String, dynamic> ? value : null;
  }

  List<dynamic> list(String key) {
    final value = raw[key];
    return value is List ? value : const [];
  }

  num number(String key, {List<String> fallbacks = const [], num defaultValue = 0}) {
    for (final k in [key, ...fallbacks]) {
      final value = raw[k];
      if (value == null) continue;
      final parsed = num.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return defaultValue;
  }

  bool boolean(String key, {List<String> fallbacks = const []}) {
    for (final k in [key, ...fallbacks]) {
      final value = raw[k];
      if (value == true) return true;
      if (value == false) return false;
      final text = value?.toString().toLowerCase().trim();
      if (text == 'true' || text == '1' || text == 'yes') return true;
      if (text == 'false' || text == '0' || text == 'no') return false;
    }
    return false;
  }

  String nestedString(
    String parentKey,
    String childKey, {
    List<String> parentFallbacks = const [],
    List<String> childFallbacks = const [],
    String defaultValue = '',
  }) {
    for (final parent in [parentKey, ...parentFallbacks]) {
      final parentMap = map(parent);
      if (parentMap == null) continue;
      final nested = DynamicJsonModel(parentMap);
      final value = nested.string(
        childKey,
        fallbacks: childFallbacks,
      );
      if (value.isNotEmpty) return value;
    }
    return defaultValue;
  }

  static List<Map<String, dynamic>> parseList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      for (final key in ['results', 'data', 'items', 'completion_forms', 'custom_requests']) {
        final value = data[key];
        if (value is List) {
          return value.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    return [];
  }
}
