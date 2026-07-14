import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/core/api/api_service.dart';
import 'package:hudhud_delivery/core/l10n/context_l10n.dart';
import 'package:hudhud_delivery/features/addresses/addresses_bloc_provider.dart';
import 'package:hudhud_delivery/features/addresses/bloc/addresses_bloc.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart';
import 'package:hudhud_delivery/features/addresses/data/addresses_repository.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/address_form_screen.dart';
import 'package:hudhud_delivery/features/addresses/presentation/screens/address_map_picker_screen.dart';
import 'package:hudhud_delivery/features/addresses/presentation/widgets/address_list_tile.dart';
import 'package:hudhud_delivery/features/login/presentation/screen/login_screen.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/auth_feedback.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';

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
    AuthModal.sheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AuthScreenColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.map_outlined,
                color: AuthScreenColors.orange,
              ),
              title: Text(
                l10n.addressesAddFromMap,
                style: const TextStyle(color: AuthScreenColors.textPrimary),
              ),
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
              leading: const Icon(
                Icons.edit_outlined,
                color: AuthScreenColors.orange,
              ),
              title: Text(
                l10n.addressesAddManual,
                style: const TextStyle(color: AuthScreenColors.textPrimary),
              ),
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
    final ok = await AuthModal.confirm(
      context: context,
      title: l10n.addressesDeleteTitle,
      message: l10n.addressesDeleteMessage,
      confirmLabel: l10n.actionDelete,
      cancelLabel: l10n.actionCancel,
      destructive: true,
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

    final ok = await AuthModal.dialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AuthAlertDialog(
          title: l10n.addressesBulkDeleteTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.addressesBulkDeleteMessage(ids.length)),
              if (hasDefault) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AuthScreenColors.orange,
                  title: Text(
                    l10n.addressesBulkDeleteForce,
                    style: const TextStyle(color: AuthScreenColors.textPrimary),
                  ),
                  value: force,
                  onChanged: (v) => setDialogState(() => force = v ?? false),
                ),
              ],
            ],
          ),
          actions: [
            AuthDialogAction(
              label: l10n.actionCancel,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            AuthDialogAction(
              label: l10n.actionDelete,
              filled: true,
              destructive: true,
              onPressed: () => Navigator.pop(ctx, true),
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
      return ProfileDarkPage(
        title: l10n.addressesTitle,
        body: const Center(
          child: CircularProgressIndicator(color: AuthScreenColors.orange),
        ),
      );
    }

    if (_isLoggedIn == false) {
      return ProfileDarkPage(
        title: l10n.addressesTitle,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.addressesSignInTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AuthScreenColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.addressesSignInSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AuthScreenColors.textSecondary),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AuthScreenColors.orange,
                    foregroundColor: Colors.black,
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

    return ProfileDarkPage(
      title: l10n.addressesTitle,
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
      floatingActionButton: BlocBuilder<AddressesBloc, AddressesState>(
        builder: (context, state) {
          if (state is AddressesLoaded && state.isSelectionMode) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: onAdd,
            backgroundColor: AuthScreenColors.orange,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add),
            label: Text(l10n.addressesAdd),
          );
        },
      ),
      body: BlocBuilder<AddressesBloc, AddressesState>(
        builder: (context, state) {
          if (state is AddressesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AuthScreenColors.orange),
            );
          }
          if (state is AddressesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.addressesLoadError,
                    style: const TextStyle(color: AuthScreenColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AuthScreenColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AuthScreenColors.orange,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => context
                        .read<AddressesBloc>()
                        .add(const LoadAddressesEvent()),
                    child: Text(l10n.actionRetry),
                  ),
                ],
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
                      const Icon(
                        Icons.location_off_outlined,
                        size: 64,
                        color: AuthScreenColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.addressesEmptyTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AuthScreenColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.addressesEmptySubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AuthScreenColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              color: AuthScreenColors.orange,
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
                  itemCount:
                      state.addresses.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.addresses.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AuthScreenColors.orange,
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
