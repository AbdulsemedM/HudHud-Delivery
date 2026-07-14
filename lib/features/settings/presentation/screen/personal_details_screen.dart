import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/utils/avatar_util.dart';
import 'package:hudhud_delivery/core/widgets/user_avatar.dart';
import 'package:hudhud_delivery/app/services/auth_service.dart';
import 'package:hudhud_delivery/features/login/presentation/theme/auth_screen_colors.dart';
import 'package:hudhud_delivery/features/settings/presentation/widgets/profile_dark_page.dart';
import 'package:hudhud_delivery/models/user_model.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final user = await _authService.getUserProfile(forceRefresh: true) ??
        await _authService.getStoredUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
        _errorMessage = user == null ? 'Failed to load profile' : null;
      });
    }
  }

  String _formatDateOfBirth(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('d MMM yyyy').format(date);
  }

  String get _initial {
    final name = _user?.name?.trim() ?? '';
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileDarkPage(
      title: 'Personal Details',
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: _PersonalDetailsShimmer(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_errorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AuthScreenColors.lavender.withValues(
                              alpha: 0.7,
                            ),
                            width: 2,
                          ),
                        ),
                        child: getDisplayAvatarUrl(_user) != null
                            ? UserAvatar(
                                radius: 50,
                                imageUrl: getDisplayAvatarUrl(_user),
                                backgroundColor: AuthScreenColors.surfaceBorder,
                              )
                            : CircleAvatar(
                                radius: 50,
                                backgroundColor: AuthScreenColors.surfaceBorder,
                                child: Text(
                                  _initial,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AuthScreenColors.textPrimary,
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AuthScreenColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AuthScreenColors.orange,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: AuthScreenColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user?.name ?? '—',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AuthScreenColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '—',
                    style: const TextStyle(
                      color: AuthScreenColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _DetailCard(
                          icon: Icons.person,
                          label: 'Full Name',
                          value: _user?.name ?? '—',
                        ),
                        const SizedBox(height: 16),
                        _DetailCard(
                          icon: Icons.phone,
                          label: 'Phone number',
                          value: _user?.phone ?? '—',
                        ),
                        const SizedBox(height: 16),
                        _DetailCard(
                          icon: Icons.email,
                          label: 'Email address',
                          value: _user?.email ?? '—',
                        ),
                        const SizedBox(height: 16),
                        _DetailCard(
                          icon: Icons.calendar_today,
                          label: 'Date of birth',
                          value: _formatDateOfBirth(_user?.dateOfBirth),
                        ),
                        if (_user?.referralCode != null &&
                            _user!.referralCode!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _DetailCard(
                            icon: Icons.card_giftcard,
                            label: 'Referral code',
                            value: _user!.referralCode!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AuthScreenColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthScreenColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AuthScreenColors.orange.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: AuthScreenColors.orange, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AuthScreenColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AuthScreenColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalDetailsShimmer extends StatelessWidget {
  const _PersonalDetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AuthScreenColors.surface,
            highlightColor: AuthScreenColors.surfaceBorder,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: AuthScreenColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      }),
    );
  }
}
