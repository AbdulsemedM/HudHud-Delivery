import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/system_ui_style.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';

import '../../data/models/home_feed.dart';
import '../widgets/home_feed_widgets.dart';

/// "See all" grid for a home-feed collection.
class HomeCollectionScreen extends StatelessWidget {
  const HomeCollectionScreen({super.key, required this.collection});

  final HomeFeedCollection collection;

  @override
  Widget build(BuildContext context) {
    final title = collection.title.isNotEmpty
        ? collection.title
        : context.l10n.growthCollectionFallbackTitle;
    return Theme(
      data: HomeColors.themeFor(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: systemUiOverlayFor(context),
        child: Scaffold(
          backgroundColor: HomeColors.backgroundOf(context),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: HomeColors.backgroundOf(context),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 26),
              color: HomeColors.textPrimaryOf(context),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.3,
                color: HomeColors.textPrimaryOf(context),
              ),
            ),
          ),
          body: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: collection.items.length,
            itemBuilder: (context, index) =>
                HomeFeedItemCard(item: collection.items[index]),
          ),
        ),
      ),
    );
  }
}
