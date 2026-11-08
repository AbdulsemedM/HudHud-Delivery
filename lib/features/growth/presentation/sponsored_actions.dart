import 'dart:async';

import 'package:flutter/material.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/delivery/presentation/screens/store_detail_screen.dart';

import '../data/growth_repository.dart';
import '../data/models/sponsored.dart';

/// Opens a sponsored vendor's store. The click is reported fire-and-forget
/// (`POST /api/ads/click`); navigation never waits for it.
void openSponsoredItem(
  BuildContext context,
  SponsoredItem item, {
  GrowthRepository? repository,
}) {
  final repo = repository ?? GrowthRepository.create();
  unawaited(repo.trackAdClick(item));
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StoreDetailScreen(
        storeName: item.vendorName.isNotEmpty
            ? item.vendorName
            : context.l10n.growthStoreFallbackName,
        storeImage: item.imageUrl,
        vendorId: item.vendorId,
      ),
    ),
  );
}
