import 'dart:math' as math;

import 'package:hudhud_delivery/features/guest/model/branch_model.dart';

/// Picks the nearest branch with coordinates to [latitude]/[longitude].
///
/// Prefers active branches. Falls back to any branch with an id so a
/// `branch_id` is available for the quote API — the server may still return
/// `BRANCH_UNAVAILABLE` / `BRANCH_LOCATION_UNAVAILABLE`.
BranchModel? pickNearestActiveBranch({
  required List<BranchModel> branches,
  required double latitude,
  required double longitude,
}) {
  BranchModel? pickNearest(Iterable<BranchModel> candidates) {
    BranchModel? nearest;
    var nearestKm = double.infinity;
    for (final branch in candidates) {
      if (branch.id <= 0) continue;
      final lat = branch.locationLatitude;
      final lng = branch.locationLongitude;
      if (lat == null || lng == null) continue;
      final km = haversineDistanceKm(latitude, longitude, lat, lng);
      if (km < nearestKm) {
        nearestKm = km;
        nearest = branch;
      }
    }
    return nearest;
  }

  final active = branches.where((b) => b.isActive);
  final nearestActive = pickNearest(active);
  if (nearestActive != null) return nearestActive;

  final nearestAny = pickNearest(branches);
  if (nearestAny != null) return nearestAny;

  for (final branch in active) {
    if (branch.id > 0) return branch;
  }
  for (final branch in branches) {
    if (branch.id > 0) return branch;
  }
  return null;
}

/// Great-circle distance in kilometres between two WGS84 points.
double haversineDistanceKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
