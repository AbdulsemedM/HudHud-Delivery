/// Compares dotted version strings (e.g. `1.0.0` / `1.0.0+11`).
///
/// Returns negative if [a] < [b], zero if equal, positive if [a] > [b].
int compareVersionStrings(String a, String b) {
  final aParts = _parse(a);
  final bParts = _parse(b);
  final len = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < len; i++) {
    final av = i < aParts.length ? aParts[i] : 0;
    final bv = i < bParts.length ? bParts[i] : 0;
    if (av != bv) return av.compareTo(bv);
  }
  return 0;
}

List<int> _parse(String raw) {
  final core = raw.trim().split('+').first.split('-').first;
  if (core.isEmpty) return const [0];
  return core.split('.').map((part) {
    final match = RegExp(r'^\d+').firstMatch(part);
    return match == null ? 0 : int.parse(match.group(0)!);
  }).toList();
}
