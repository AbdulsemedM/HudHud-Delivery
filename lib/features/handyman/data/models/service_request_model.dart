// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:hudhud_delivery/features/service_types/model/service_type_model.dart';

/// Model for a service request from the handyman API.
class ServiceRequestModel {
  final int id;
  final int userId;
  final int? providerId;
  final int serviceTypeId;
  final String serviceTypeCode;
  final String title;
  final String description;
  final String status;
  final String? scheduledAt;
  final int? estimatedDuration;
  final String? estimatedCost;
  final String? actualCost;
  final String location;
  final String? latitude;
  final String? longitude;
  final ServiceRequestRequirements? requirements;
  final List<dynamic> attachments;
  final String? providerNotes;
  final dynamic userRating;
  final String? userFeedback;
  final String? acceptedAt;
  final String? startedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? cancellationReason;
  final String? createdAt;
  final String? updatedAt;
  final bool isScheduled;
  final bool hasQuote;
  final bool hasAcceptedQuote;
  final int quotesCount;
  final String? formattedEstimatedCost;
  final String? formattedActualCost;
  final ServiceTypeModel? serviceType;
  final Map<String, dynamic>? provider;

  const ServiceRequestModel({
    required this.id,
    required this.userId,
    this.providerId,
    required this.serviceTypeId,
    required this.serviceTypeCode,
    required this.title,
    required this.description,
    required this.status,
    this.scheduledAt,
    this.estimatedDuration,
    this.estimatedCost,
    this.actualCost,
    required this.location,
    this.latitude,
    this.longitude,
    this.requirements,
    this.attachments = const [],
    this.providerNotes,
    this.userRating,
    this.userFeedback,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.createdAt,
    this.updatedAt,
    this.isScheduled = false,
    this.hasQuote = false,
    this.hasAcceptedQuote = false,
    this.quotesCount = 0,
    this.formattedEstimatedCost,
    this.formattedActualCost,
    this.serviceType,
    this.provider,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    final requirementsRaw = json['requirements'];
    ServiceRequestRequirements? requirements;
    if (requirementsRaw is Map<String, dynamic>) {
      requirements = ServiceRequestRequirements.fromJson(requirementsRaw);
    }

    final serviceTypeRaw = json['service_type'];
    ServiceTypeModel? serviceType;
    if (serviceTypeRaw is Map<String, dynamic>) {
      serviceType = ServiceTypeModel.fromJson(serviceTypeRaw);
    }

    final attachmentsRaw = json['attachments'];
    final attachmentsList =
        attachmentsRaw is List ? List<dynamic>.from(attachmentsRaw) : <dynamic>[];

    final providerRaw = json['provider'];
    Map<String, dynamic>? provider;
    if (providerRaw is Map<String, dynamic>) {
      provider = providerRaw;
    }

    return ServiceRequestModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      providerId: json['provider_id'] as int?,
      serviceTypeId: json['service_type_id'] as int? ?? 0,
      serviceTypeCode: json['service_type_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      scheduledAt: json['scheduled_at'] as String?,
      estimatedDuration: json['estimated_duration'] as int?,
      estimatedCost: json['estimated_cost']?.toString(),
      actualCost: json['actual_cost']?.toString(),
      location: json['location'] as String? ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      requirements: requirements,
      attachments: attachmentsList,
      providerNotes: json['provider_notes'] as String?,
      userRating: json['user_rating'],
      userFeedback: json['user_feedback'] as String?,
      acceptedAt: json['accepted_at'] as String?,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      isScheduled: json['is_scheduled'] == true,
      hasQuote: json['has_quote'] == true,
      hasAcceptedQuote: json['has_accepted_quote'] == true,
      quotesCount: json['quotes_count'] as int? ?? 0,
      formattedEstimatedCost: json['formatted_estimated_cost'] as String?,
      formattedActualCost: json['formatted_actual_cost'] as String?,
      serviceType: serviceType,
      provider: provider,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider_id': providerId,
      'service_type_id': serviceTypeId,
      'service_type_code': serviceTypeCode,
      'title': title,
      'description': description,
      'status': status,
      'scheduled_at': scheduledAt,
      'estimated_duration': estimatedDuration,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'requirements': requirements?.toJson(),
      'attachments': attachments,
      'provider_notes': providerNotes,
      'user_rating': userRating,
      'user_feedback': userFeedback,
      'accepted_at': acceptedAt,
      'started_at': startedAt,
      'completed_at': completedAt,
      'cancelled_at': cancelledAt,
      'cancellation_reason': cancellationReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_scheduled': isScheduled,
      'has_quote': hasQuote,
      'has_accepted_quote': hasAcceptedQuote,
      'quotes_count': quotesCount,
      'formatted_estimated_cost': formattedEstimatedCost,
      'formatted_actual_cost': formattedActualCost,
      'service_type': serviceType?.toJson(),
      'provider': provider,
    };
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}

/// Requirements nested in a service request.
class ServiceRequestRequirements {
  final List<String> skills;
  final List<String> tools;
  final int? estimatedHours;

  const ServiceRequestRequirements({
    this.skills = const [],
    this.tools = const [],
    this.estimatedHours,
  });

  factory ServiceRequestRequirements.fromJson(Map<String, dynamic> json) {
    final skillsRaw = json['skills'];
    final skillsList = skillsRaw is List
        ? skillsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final toolsRaw = json['tools'];
    final toolsList = toolsRaw is List
        ? toolsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return ServiceRequestRequirements(
      skills: skillsList,
      tools: toolsList,
      estimatedHours: json['estimated_hours'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skills': skills,
      'tools': tools,
      'estimated_hours': estimatedHours,
    };
  }
}
