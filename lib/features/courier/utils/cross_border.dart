/// Can one rider cover this delivery?
///
/// Only the pickup is checked against the configured service areas, so a
/// delivery from Addis Ababa to Jeddah was accepted all the way to courier
/// search.
///
/// The obvious fix — require the drop-off to resolve to a service area too —
/// is wrong. `DeliveryServiceAreaService::resolve()` matches city aliases as
/// substrings of the address text, so a real drop-off in a village outside
/// any configured city resolves to nothing. Refusing those would block
/// deliveries we can and do make, which is a worse failure than the one being
/// fixed.
///
/// The signal that actually separates Jeddah from Sululta is the COUNTRY. A
/// rider on a motorbike does not cross a border; a rider reaching a village
/// two valleys over does it every day. This needs no configuration and cannot
/// block a destination inside the country already being worked in.
library;

/// True only when both countries are known AND different.
///
/// AN UNKNOWN COUNTRY IS NOT EVIDENCE. Google does not always return one —
/// a plus-code hit, a sparse reverse geocode — and treating "we don't know"
/// as "different country" would refuse ordinary deliveries for want of a
/// field. Same rule as the pickup check: a failed lookup is not a refusal.
///
/// Comparison is case- and whitespace-insensitive because the two ends can
/// come from different Google responses: an autocomplete hit for one and a
/// reverse geocode for the other.
bool isCrossBorder(String? pickupCountry, String? dropoffCountry) {
  final from = pickupCountry?.trim();
  final to = dropoffCountry?.trim();

  if (from == null || from.isEmpty) return false;
  if (to == null || to.isEmpty) return false;

  return from.toLowerCase() != to.toLowerCase();
}
