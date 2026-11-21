/// Whether HudHud delivers where the customer is pointing.
///
/// From `GET /api/coverage?lat=&lng=`. The server is authoritative here in a
/// way the device cannot be: a city counts as open only when its market is
/// active AND it has an enabled pricing zone, and the app knows nothing about
/// pricing zones. A market with no price list can only produce a checkout that
/// fails, which is why "active" alone is not the test.
///
/// The app was never asking. The endpoint shipped with the city-pricing work
/// and was verified on production, while `CityScope.allowsPin` - the only
/// check in the pin flow - returns true whenever city enforcement is off,
/// which is the default. So a customer could confirm a pin in a town we do not
/// serve, walk through the whole order and meet the refusal at checkout.
class CityCoverage {
  const CityCoverage({
    required this.served,
    required this.status,
    required this.message,
    this.city,
    this.launching = false,
    this.openCities = const [],
  });

  /// True only when an order placed here can actually be quoted.
  final bool served;

  /// `served`, `coming_soon` or `not_served`.
  final String status;

  /// The server's own wording, ready to display. Not rebuilt on the device:
  /// it names the city and distinguishes "coming soon" from "nowhere near us",
  /// and a second copy of that wording would drift from the first.
  final String message;

  final String? city;

  /// True when the city is on the map but not open yet, so the screen can
  /// offer "notify me" rather than a flat refusal.
  final bool launching;

  /// Cities currently open, for a "where we operate" list.
  final List<String> openCities;

  bool get isComingSoon => status == 'coming_soon';

  /// Parses `{success: true, data: {...}}` as the endpoint sends it.
  static CityCoverage? fromResponseBody(dynamic body) {
    if (body is! Map) return null;
    return fromJson(body['data']);
  }

  static CityCoverage? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final status = raw['status']?.toString();
    final message = raw['message']?.toString();
    if (status == null || status.isEmpty) return null;
    if (message == null || message.isEmpty) return null;

    final open = <String>[];
    final rawOpen = raw['open_cities'];
    if (rawOpen is List) {
      for (final city in rawOpen) {
        if (city is Map) {
          final name = city['name']?.toString();
          if (name != null && name.trim().isNotEmpty) open.add(name.trim());
        }
      }
    }

    return CityCoverage(
      served: raw['served'] == true,
      status: status,
      message: message,
      city: raw['city']?.toString(),
      launching: raw['launching'] == true,
      openCities: open,
    );
  }
}
