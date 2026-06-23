class TipHistoryQuery {
  final String? status;
  final int page;
  final int perPage;

  const TipHistoryQuery({
    this.status,
    this.page = 1,
    this.perPage = 15,
  });

  Map<String, dynamic> toParams() {
    return {
      'page': page,
      'per_page': perPage,
      if (status != null && status!.isNotEmpty) 'status': status,
    };
  }
}
