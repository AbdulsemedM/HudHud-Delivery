import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
import 'package:hudhud_delivery/features/addresses/addresses_bloc_provider.dart';
import 'package:hudhud_delivery/features/addresses/bloc/addresses_bloc.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_repository.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/address_form_screen.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/address_map_picker_screen.dart';
import 'package:hudhud_delivery/features/addresses/presentation/widgets/address_list_tile.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

class AddressesListScreen extends StatefulWidget {
  const AddressesListScreen({super.key});

  @override
  State<AddressesListScreen> createState() => _AddressesListScreenState();
}

class _AddressesListScreenState extends State<AddressesListScreen> {
  final AuthService _authService = AuthService();
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await _authService.initialize();
    if (mounted) {
      setState(() => _isLoggedIn = _authService.isLoggedIn);
    }
  }

  void _showAddOptions(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.r20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.mutedLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppColors.rFull),
              ),
            ),
            ListTile(
              leading: Icon(Icons.map_outlined, color: AppColors.primaryColor),
              title: Text(l10n.addressesAddFromMap),
              onTap: () async {
                Navigator.pop(ctx);
                final mapResult = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddressMapPickerScreen(),
                  ),
                );
                if (mapResult == null || !context.mounted) return;
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<AddressesBloc>(),
                      child: AddressFormScreen(
                        mapPrefill: mapResult,
                        fromMap: true,
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: AppColors.primaryColor),
              title: Text(l10n.addressesAddManual),
              onTap: () async {
                Navigator.pop(ctx);
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<AddressesBloc>(),
                      child: const AddressFormScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required int id,
  }) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addressesDeleteTitle),
        content: Text(l10n.addressesDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AddressesBloc>().add(DeleteAddressEvent(id));
    }
  }

  Future<void> _confirmBulkDelete(BuildContext context, AddressesLoaded state) async {
    final l10n = context.l10n;
    final ids = state.selectedIds.toList();
    final hasDefault = state.addresses
        .any((a) => ids.contains(a.id) && a.isDefault);
    var force = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.addressesBulkDeleteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.addressesBulkDeleteMessage(ids.length)),
              if (hasDefault) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.addressesBulkDeleteForce),
                  value: force,
                  onChanged: (v) => setDialogState(() => force = v ?? false),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.actionDelete),
            ),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AddressesBloc>().add(
            BulkDeleteAddressesEvent(ids: ids, force: force),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_isLoggedIn == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.addressesTitle)),
        body: const _AddressesShimmerList(),
      );
    }

    if (_isLoggedIn == false) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.addressesTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.addressesSignInTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.addressesSignInSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    minimumSize: const Size(160, 48),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(l10n.actionSignIn),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return addressesBlocProvider(
      child: BlocListener<AddressesBloc, AddressesState>(
        listener: (context, state) {
          if (state is AddressesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Builder(
          builder: (innerContext) => _AddressesListBody(
            onAdd: () => _showAddOptions(innerContext),
            onConfirmDelete: (id) => _confirmDelete(innerContext, id: id),
            onConfirmBulkDelete: (s) => _confirmBulkDelete(innerContext, s),
          ),
        ),
      ),
    );
  }
}

class _AddressesListBody extends StatelessWidget {
  final VoidCallback onAdd;
  final void Function(int id) onConfirmDelete;
  final void Function(AddressesLoaded state) onConfirmBulkDelete;

  const _AddressesListBody({
    required this.onAdd,
    required this.onConfirmDelete,
    required this.onConfirmBulkDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.addressesTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          BlocBuilder<AddressesBloc, AddressesState>(
            builder: (context, state) {
              if (state is! AddressesLoaded) return const SizedBox.shrink();
              if (state.isSelectionMode) {
                return Row(
                  children: [
                    if (state.selectedIds.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onConfirmBulkDelete(state),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context
                          .read<AddressesBloc>()
                          .add(const ExitSelectionModeEvent()),
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.checklist),
                tooltip: l10n.addressesSelect,
                onPressed: () => context
                    .read<AddressesBloc>()
                    .add(const EnterSelectionModeEvent()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<AddressesBloc, AddressesState>(
        builder: (context, state) {
          if (state is AddressesLoaded && state.isSelectionMode) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: onAdd,
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.add),
            label: Text(l10n.addressesAdd),
          );
        },
      ),
      body: BlocBuilder<AddressesBloc, AddressesState>(
        builder: (context, state) {
          if (state is AddressesLoading) {
            return const _AddressesShimmerList();
          }
          if (state is AddressesError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.addressesLoadError,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      onPressed: () => context
                          .read<AddressesBloc>()
                          .add(const LoadAddressesEvent()),
                      child: Text(l10n.actionRetry),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is AddressesLoaded) {
            if (state.addresses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animations/browse.json',
                        width: 200,
                        height: 160,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addressesEmptyTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addressesEmptySubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addressesAdd),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async {
                context.read<AddressesBloc>().add(const RefreshAddressesEvent());
                await context.read<AddressesBloc>().stream.firstWhere(
                      (s) => s is AddressesLoaded || s is AddressesError,
                    );
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification &&
                      n.metrics.extentAfter < 200 &&
                      state.hasMore &&
                      !state.isLoadingMore) {
                    context
                        .read<AddressesBloc>()
                        .add(const LoadMoreAddressesEvent());
                  }
                  return false;
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 88),
                  itemCount:
                      state.addresses.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.addresses.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryColor,
                          ),
                        ),
                      );
                    }
                    final address = state.addresses[index];
                    return AddressListTile(
                      address: address,
                      isSelectionMode: state.isSelectionMode,
                      isSelected: state.selectedIds.contains(address.id),
                      onTap: () {
                        if (state.isSelectionMode) {
                          context.read<AddressesBloc>().add(
                                ToggleSelectionEvent(address.id),
                              );
                        }
                      },
                      onLongPress: () {
                        if (!state.isSelectionMode) {
                          context
                              .read<AddressesBloc>()
                              .add(const EnterSelectionModeEvent());
                          context.read<AddressesBloc>().add(
                                ToggleSelectionEvent(address.id),
                              );
                        }
                      },
                      onSetDefault: () => context.read<AddressesBloc>().add(
                            SetDefaultAddressEvent(address.id),
                          ),
                      onEdit: () async {
                        await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<AddressesBloc>(),
                              child: AddressFormScreen(existing: address),
                            ),
                          ),
                        );
                      },
                      onDelete: () => onConfirmDelete(address.id),
                    );
                  },
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _AddressesShimmerList extends StatelessWidget {
  const _AddressesShimmerList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceLight;
    final highlightColor = isDark ? AppColors.darkCard : Colors.white;
    final placeholder = isDark ? AppColors.darkCard : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 6,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: placeholder,
                    borderRadius: BorderRadius.circular(AppColors.r10),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: placeholder,
                          borderRadius: BorderRadius.circular(AppColors.r8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: placeholder,
                          borderRadius: BorderRadius.circular(AppColors.r8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loads default address once (e.g. dashboard). Fire-and-forget.
Future<void> syncDefaultAddressFromApi() async {
  try {
    final repo = AddressesRepository(
      addressesDataProvider: AddressesDataProvider(
        apiService: ApiService.instance,
      ),
    );
    final auth = AuthService();
    await auth.initialize();
    if (!auth.isLoggedIn) return;
    await repo.getDefaultAddress();
  } catch (_) {}
}
