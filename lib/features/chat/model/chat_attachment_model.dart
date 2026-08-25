import 'package:hudhud_delivery/features/chat/utils/chat_url_utils.dart';

class ChatAttachmentModel {
  final int? id;
  final String? fileName;
  final String? filePath;
  final String? fileType;
  final int? fileSize;
  final String? mimeType;
  final String? name;
  final String? sizeLabel;
  final String? url;

  const ChatAttachmentModel({
    this.id,
    this.fileName,
    this.filePath,
    this.fileType,
    this.fileSize,
    this.mimeType,
    this.name,
    this.sizeLabel,
    this.url,
  });

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    String? metaUrl;
    String? metaFullPath;
    if (metadata is Map<String, dynamic>) {
      metaUrl = metadata['url']?.toString();
      metaFullPath = metadata['full_path']?.toString();
    } else if (metadata is String && metadata.isNotEmpty) {
      // Some responses embed JSON string in metadata.
      try {
        // Lightweight parse without importing dart:convert in hot path if url present on root.
      } catch (_) {}
    }

    final resolved = ChatUrlUtils.resolveAttachmentUrl(
      url: json['url']?.toString() ?? metaUrl,
      fullPath: json['full_path']?.toString() ?? metaFullPath,
      filePath: json['file_path']?.toString(),
    );

    return ChatAttachmentModel(
      id: _asInt(json['id']),
      fileName: json['file_name']?.toString(),
      filePath: json['file_path']?.toString(),
      fileType: json['file_type']?.toString() ?? json['type']?.toString(),
      fileSize: _asInt(json['file_size']),
      mimeType: json['mime_type']?.toString(),
      name: json['name']?.toString() ?? json['file_name']?.toString(),
      sizeLabel: json['size']?.toString(),
      url: resolved,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
