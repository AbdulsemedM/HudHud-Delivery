// ignore_for_file: public_member_api_docs, sort_constructors_first

/// Model for a service quote from a handyman.
class ServiceQuoteModel {
  final int id;
  final int serviceRequestId;
  final int handymanId;
  final String amount;
  final String? description;
  final dynamic breakdown;
  final String? validUntil;
  final String status;
  final String? rejectionReason;
  final String? createdAt;
  final String? updatedAt;
  final bool isValid;
  final int? daysUntilExpiry;
  final String? formattedAmount;
  final Map<String, dynamic>? handyman;

  const ServiceQuoteModel({
    required this.id,
    required this.serviceRequestId,
    required this.handymanId,
    required this.amount,
    this.description,
    this.breakdown,
    this.validUntil,
    required this.status,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.isValid = true,
    this.daysUntilExpiry,
    this.formattedAmount,
    this.handyman,
  });

  factory ServiceQuoteModel.fromJson(Map<String, dynamic> json) {
    final handymanRaw = json['handyman'];
    Map<String, dynamic>? handyman;
    if (handymanRaw is Map<String, dynamic>) {
      handyman = handymanRaw;
    }

    return ServiceQuoteModel(
      id: json['id'] as int? ?? 0,
      serviceRequestId: json['service_request_id'] as int? ?? 0,
      handymanId: json['handyman_id'] as int? ?? 0,
      amount: json['amount']?.toString() ?? '0',
      description: json['description'] as String?,
      breakdown: json['breakdown'],
      validUntil: json['valid_until'] as String?,
      status: json['status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      isValid: json['is_valid'] != false,
      daysUntilExpiry: json['days_until_expiry'] as int?,
      formattedAmount: json['formatted_amount'] as String?,
      handyman: handyman,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_request_id': serviceRequestId,
      'handyman_id': handymanId,
      'amount': amount,
      'description': description,
      'breakdown': breakdown,
      'valid_until': validUntil,
      'status': status,
      'rejection_reason': rejectionReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_valid': isValid,
      'days_until_expiry': daysUntilExpiry,
      'formatted_amount': formattedAmount,
      'handyman': handyman,
    };
  }

  String get handymanName => handyman?['name'] as String? ?? 'Handyman';
}
