import '../api/api_constants.dart';
import '../../models/user_model.dart';

/// Returns the display URL for a user's avatar, or null if none available.
/// Prefers avatar_url (full URL from API), then builds URL from avatar path.
String? getDisplayAvatarUrl(UserModel? user) {
  if (user == null) return null;
  // Prefer avatar_url (full URL from API)
  if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
    return user.avatarUrl;
  }
  // Fall back to avatar (path)
  final avatar = user.avatar;
  if (avatar == null || avatar.isEmpty) return null;
  if (avatar.startsWith('http')) return avatar;
  final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  return '$base/${avatar.startsWith('/') ? avatar.substring(1) : avatar}';
}
