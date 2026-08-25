import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/core/theme/service_tab_palette.dart';
import 'package:hudhud_delivery/core/utils/snackbar_util.dart';
// import 'package:hudhud_delivery/features/handyman/presentation/screens/handyman_screen.dart';
import 'package:hudhud_delivery/features/home/presentation/theme/home_colors.dart';
import 'package:hudhud_delivery/features/home/presentation/widgets/service_coming_soon_screen.dart';
import 'package:hudhud_delivery/features/service_types/bloc/service_types_bloc.dart';
import 'package:hudhud_delivery/features/service_types/data/data_provider/service_types_data_provider.dart';
import 'package:hudhud_delivery/features/service_types/data/repository/service_types_repository.dart';
import 'package:hudhud_delivery/features/service_types/model/service_type_model.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static IconData _iconForServiceCode(String code) {
    switch (code.toLowerCase()) {
      case 'grocery':
        return Icons.shopping_basket_rounded;
      case 'handyman':
        return Icons.handyman_rounded;
      case 'messenger':
        return Icons.local_shipping_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'ride_hailing':
        return Icons.local_taxi_rounded;
      case 'supermarket':
        return Icons.store_rounded;
      case 'food_delivery':
        return Icons.delivery_dining_rounded;
      default:
        return Icons.miscellaneous_services_rounded;
    }
  }

  static Color _colorForServiceCode(String code) {
    switch (code.toLowerCase()) {
      case 'grocery':
        return const Color(0xFF4CAF50);
      case 'handyman':
        return const Color(0xFF795548);
      case 'messenger':
        return const Color(0xFF2196F3);
      case 'restaurant':
        return const Color(0xFFE91E63);
      case 'ride_hailing':
        return const Color(0xFFFFC107);
      case 'supermarket':
        return const Color(0xFF009688);
      case 'food_delivery':
        return const Color(0xFFFF5722);
      default:
        return AppColors.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ServiceTypesRepository(
      dataProvider: ServiceTypesDataProvider(apiService: ApiService.instance),
    );
    return BlocProvider(
      create: (context) =>
          ServiceTypesBloc(repository)..add(FetchServiceTypesEvent()),
      child: const _ServicesScreenBody(),
    );
  }
}

class _ServicesScreenBody extends StatelessWidget {
  const _ServicesScreenBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.servicesScreenTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: theme.colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: theme.dividerColor.withValues(alpha: 0.5),
            height: 1,
          ),
        ),
      ),
      body: BlocBuilder<ServiceTypesBloc, ServiceTypesState>(
        builder: (context, state) {
          if (state is ServiceTypesLoading) {
            return const _LoadingState();
          }
          if (state is ServiceTypesFailure) {
            return _ErrorState(
              message: state.errorMessage,
              onRetry: () => context
                  .read<ServiceTypesBloc>()
                  .add(FetchServiceTypesEvent()),
            );
          }
          if (state is ServiceTypesSuccess) {
            final serviceTypes = state.serviceTypes;
            if (serviceTypes.isEmpty) {
              return const _EmptyState();
            }
            return _ServicesGrid(serviceTypes: serviceTypes);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ServiceSkeleton(),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 14,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 10,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.servicesErrorTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.actionTryAgain),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.miscellaneous_services_outlined,
                size: 56,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.servicesEmptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.servicesEmptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final List<ServiceTypeModel> serviceTypes;

  const _ServicesGrid({required this.serviceTypes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.servicesWhatCanWeHelp,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.servicesAvailableCount(serviceTypes.length),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final service = serviceTypes[index];
                return _ServiceCard(service: service);
              },
              childCount: serviceTypes.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceTypeModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final icon = ServicesScreen._iconForServiceCode(service.code);
    final color = ServicesScreen._colorForServiceCode(service.code);
    final iconUrl = service.iconUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (service.code == 'handyman') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  backgroundColor: HomeColors.backgroundOf(context),
                  appBar: AppBar(
                    backgroundColor: HomeColors.backgroundOf(context),
                    foregroundColor: HomeColors.textPrimaryOf(context),
                    title: Text(context.l10n.homeTabHandyman),
                  ),
                  body: const ServiceComingSoonScreen(
                    mode: HomeServiceMode.handyman,
                  ),
                ),
              ),
            );
            return;
          }
          if (service.code == 'grocery' || service.code == 'food') {
            SnackbarUtil.showComingSoon(
              context,
              context.l10n.foodComingSoonSubtitle,
            );
            return;
          }
          if (service.code == 'taxi') {
            SnackbarUtil.showComingSoon(
              context,
              context.l10n.taxiComingSoonSubtitle,
            );
            return;
          }
          // TODO: other services
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: iconUrl != null && iconUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              iconUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _IconPlaceholder(
                                icon: icon,
                                color: color,
                              ),
                            ),
                          )
                        : _IconPlaceholder(icon: icon, color: color),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (service.description != null &&
                          service.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconPlaceholder extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconPlaceholder({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 32, color: color),
    );
  }
}
