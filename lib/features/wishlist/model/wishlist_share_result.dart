class WishlistShareResult {
  final String shareToken;
  final String shareUrl;
  final DateTime? expiresAt;

  const WishlistShareResult({
    required this.shareToken,
    required this.shareUrl,
    this.expiresAt,
  });

  factory WishlistShareResult.fromJson(Map<String, dynamic> json) {
    return WishlistShareResult(
      shareToken: json['share_token']?.toString() ?? '',
      shareUrl: json['share_url']?.toString() ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
    );
  }
}
