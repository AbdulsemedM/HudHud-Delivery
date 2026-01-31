import 'package:hudhud_delivery/features/home/model/category_model.dart';

import '../data_provider/home_data_provider.dart';

class HomeRepository {
  final HomeDataProvider homeDataProvider;
  HomeRepository({required this.homeDataProvider});

  Future<List<CategoryModel>> getCategories() async {
    final response = await homeDataProvider.getCategories();
    if (response['statusCode'] == 200) {
      final body = response['data'] as Map<String, dynamic>?;
      final paginated = body?['data'] as Map<String, dynamic>?;
      final list = paginated?['data'] as List?;
      if (list == null) return [];
      return list
          .map((e) => CategoryModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(response['errorMessage'] ?? 'Failed to load categories');
    }
  }
}
