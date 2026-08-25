import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/features/sos/bloc/sos_bloc.dart';
import 'package:hudhud_delivery/features/sos/model/sos_alert_model.dart';
import 'package:hudhud_delivery/features/sos/sos_bloc_provider.dart';
import 'package:hudhud_delivery/l10n/app_localizations.dart';

class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return sosBlocProvider(
      child: const _SosHistoryBody(),
    );
  }
}

class _SosHistoryBody extends StatefulWidget {
  const _SosHistoryBody();

  @override
  State<_SosHistoryBody> createState() => _SosHistoryBodyState();
}

class _SosHistoryBodyState extends State<_SosHistoryBody> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    context.read<SosBloc>().add(LoadSosHistoryEvent(statusFilter: _statusFilter));
  }

  void _reload({String? status}) {
    setState(() => _statusFilter = status);
    context.read<SosBloc>().add(LoadSosHistoryEvent(statusFilter: status));
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileDarkPage(
      title: l10n.sosHistory,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.sosStatusAll),
                  selected: _statusFilter == null,
                  selectedColor: AuthScreenColors.orange,
                  checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    color: _statusFilter == null
                        ? Theme.of(context).colorScheme.onPrimary
                        : AuthScreenColors.textPrimaryOf(context),
                  ),
                  backgroundColor: AuthScreenColors.surfaceOf(context),
                  side: BorderSide(color: AuthScreenColors.surfaceBorderOf(context)),
                  onSelected: (_) => _reload(status: null),
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.sosStatusActive),
                  selected: _statusFilter == 'active',
                  selectedColor: AuthScreenColors.orange,
                  checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    color: _statusFilter == 'active'
                        ? Theme.of(context).colorScheme.onPrimary
                        : AuthScreenColors.textPrimaryOf(context),
                  ),
                  backgroundColor: AuthScreenColors.surfaceOf(context),
                  side: BorderSide(color: AuthScreenColors.surfaceBorderOf(context)),
                  onSelected: (_) => _reload(status: 'active'),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<SosBloc, SosState>(
              listener: (context, state) {
                if (state is SosError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is SosLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                final history =
                    state is SosLoaded ? state.history : <SosAlertModel>[];
                final hasMore = state is SosLoaded && state.hasMoreHistory;
                final isLoadingMore =
                    state is SosLoaded && state.isLoadingMore;

                if (history.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.sosNoHistory,
                      style: TextStyle(
                        color: AuthScreenColors.textSecondaryOf(context),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _reload(status: _statusFilter);
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: history.length + (hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index == history.length) {
                        if (isLoadingMore) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        context
                            .read<SosBloc>()
                            .add(const LoadMoreSosHistoryEvent());
                        return SizedBox.shrink();
                      }
                      final alert = history[index];
                      return Material(
                        color: AuthScreenColors.surfaceOf(context),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AuthScreenColors.surfaceBorderOf(context),
                            ),
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x33EF5350),
                            child: Icon(
                              Icons.sos,
                              color: Color(0xFFEF5350),
                            ),
                          ),
                          title: Text(
                            '${alert.alertType} · ${alert.status}',
                            style: TextStyle(
                              color: AuthScreenColors.textPrimaryOf(context),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (alert.description != null &&
                                  alert.description!.isNotEmpty)
                                Text(
                                  alert.description!,
                                  style: TextStyle(
                                    color: AuthScreenColors.textSecondaryOf(context),
                                  ),
                                ),
                              if (alert.locationAddress != null)
                                Text(
                                  alert.locationAddress!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AuthScreenColors.textMutedOf(context),
                                  ),
                                ),
                              if (alert.orderNumber != null)
                                Text(
                                  'Order: ${alert.orderNumber}',
                                  style: TextStyle(
                                    color: AuthScreenColors.textSecondaryOf(context),
                                  ),
                                ),
                              Text(
                                _formatDate(alert.createdAt),
                                style: TextStyle(
                                  color: AuthScreenColors.textMutedOf(context),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
