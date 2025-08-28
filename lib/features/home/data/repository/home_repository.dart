import 'package:hudhud_delivery/features/home/model/category_model.dart';

import '../data_provider/home_data_provider.dart';

class HomeRepository {
  final HomeDataProvider homeDataProvider;
  HomeRepository({required this.homeDataProvider});

  Future<List<CategoryModel>> getCategories() async {
    final response = await homeDataProvider.getCategories();
    if (response['statusCode'] == 200) {
      return (response['data']['data']['data'] as List)
          .map((e) => CategoryModel.fromMap(e))
          .toList();
    } else {
      throw Exception(response['errorMessage']);
    }
  }
}
