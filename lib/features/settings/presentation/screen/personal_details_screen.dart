import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hudhud_delivery/core/theme/app_colors.dart';
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
          ? Padding(
              padding: EdgeInsets.all(16),
              child: _PersonalDetailsShimmer(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_errorMessage != null) ...[
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.errorColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 20),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuthScreenColors.surfaceOf(context),
                          border: Border.all(
                            color: _indigoOf(context),
                            width: 2.5,
                          ),
                          boxShadow: AppColors.softShadow(context),
                        ),
                        child: UserAvatar(
                          radius: 50,
                          imageUrl: getDisplayAvatarUrl(_user),
                          name: _initial == '?' ? null : _initial,
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AuthScreenColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AuthScreenColors.backgroundOf(context),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    _user?.name ?? '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AuthScreenColors.textPrimaryOf(context),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _user?.email ?? '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AuthScreenColors.textMutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _DetailCard(
                          icon: Icons.person_rounded,
                          label: 'Full Name',
                          value: _user?.name ?? '—',
                        ),
                        const SizedBox(height: 12),
                        _DetailCard(
                          icon: Icons.phone_rounded,
                          color: AppColors.successColor,
                          label: 'Phone number',
                          value: _user?.phone ?? '—',
                        ),
                        const SizedBox(height: 12),
                        _DetailCard(
                          icon: Icons.email_rounded,
                          color: AuthScreenColors.orange,
                          label: 'Email address',
                          value: _user?.email ?? '—',
                        ),
                        const SizedBox(height: 12),
                        _DetailCard(
                          icon: Icons.cake_rounded,
                          color: AppColors.warningColor,
                          label: 'Date of birth',
                          value: _formatDateOfBirth(_user?.dateOfBirth),
                        ),
                        if (_user?.referralCode != null &&
                            _user!.referralCode!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DetailCard(
                            icon: Icons.card_giftcard_rounded,
                            color: AuthScreenColors.orange,
                            label: 'Referral code',
                            value: _user!.referralCode!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

Color _indigoOf(BuildContext context) => AuthScreenColors.isDark(context)
    ? AppColors.brandIndigoBright
    : AppColors.brandIndigo;

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AuthScreenColors.isDark(context);
    final tint = color ?? _indigoOf(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuthScreenColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: dark
            ? Border.all(color: AuthScreenColors.surfaceBorderOf(context))
            : null,
        boxShadow: AppColors.softShadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: tint.withValues(alpha: dark ? 0.2 : 0.11),
            ),
            child: Icon(icon, color: tint, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AuthScreenColors.textMutedOf(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AuthScreenColors.textPrimaryOf(context),
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
          padding: EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: AuthScreenColors.surfaceBorderOf(context),
            highlightColor: AuthScreenColors.surfaceOf(context),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: AuthScreenColors.surfaceBorderOf(context),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      }),
    );
  }
}
