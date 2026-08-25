class ChatParticipantModel {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? role;
  final String? email;

  const ChatParticipantModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role,
    this.email,
  });

  factory ChatParticipantModel.fromJson(Map<String, dynamic> json) {
    final pivot = json['pivot'];
    final roleFromPivot =
        pivot is Map ? pivot['role']?.toString() : null;

    return ChatParticipantModel(
      id: _asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? 'Unknown',
      avatarUrl: json['avatar_url']?.toString(),
      role: json['role']?.toString() ?? roleFromPivot,
      email: json['email']?.toString(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
