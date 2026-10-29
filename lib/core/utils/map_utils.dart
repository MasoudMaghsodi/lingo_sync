/// Safe conversion utility for dealing with Hive or untyped JSON maps.
/// Converts any nested Map (such as `_Map<dynamic, dynamic>`) recursively
/// into strongly typed `Map<String, dynamic>`.
Map<String, dynamic> safeMap(dynamic input) {
  if (input == null || input is! Map) return <String, dynamic>{};
  final Map<String, dynamic> result = {};
  input.forEach((key, value) {
    if (value is Map) {
      result[key.toString()] = safeMap(value);
    } else if (value is List) {
      result[key.toString()] = safeList(value);
    } else {
      result[key.toString()] = value;
    }
  });
  return result;
}

List<dynamic> safeList(dynamic input) {
  if (input == null || input is! List) return <dynamic>[];
  return input.map((item) {
    if (item is Map) {
      return safeMap(item);
    } else if (item is List) {
      return safeList(item);
    } else {
      return item;
    }
  }).toList();
}
