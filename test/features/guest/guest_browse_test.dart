import 'package:flutter_test/flutter_test.dart';
import 'package:hudhud_delivery/app/services/guest_browse_service.dart';
import 'package:hudhud_delivery/features/categories/model/category_tree_model.dart';
import 'package:hudhud_delivery/features/guest/data/public_catalog_repository.dart';
import 'package:hudhud_delivery/features/guest/model/branch_model.dart';
import 'package:hudhud_delivery/features/products/model/products_list_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GuestBrowseService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await GuestBrowseService().clearGuestBrowseMode();
    });

    test('enterGuestBrowseMode sets active flag', () async {
      final service = GuestBrowseService();
      expect(await service.isActive(), isFalse);
      await service.enterGuestBrowseMode();
      expect(await service.isActive(), isTrue);
      expect(service.isGuestBrowseMode, isTrue);
    });

    test('clearGuestBrowseMode resets flag', () async {
      final service = GuestBrowseService();
      await service.enterGuestBrowseMode();
      await service.clearGuestBrowseMode();
      expect(await service.isActive(), isFalse);
    });
  });

  group('ProductsListResult public API', () {
    test('parses empty filtered products response', () {
      const json = {
        'success': true,
        'data': {
          'current_page': 1,
          'data': <dynamic>[],
          'per_page': 15,
          'total': 0,
          'last_page': 1,
        },
      };
      final result = ProductsListResult.fromResponseData(json);
      expect(result.items, isEmpty);
      expect(result.total, 0);
      expect(result.currentPage, 1);
      expect(result.lastPage, 1);
      expect(result.hasMore, isFalse);
    });

    test('parses paginated products with items', () {
      const json = {
        'success': true,
        'data': {
          'current_page': 1,
          'data': [
            {
              'id': 1,
              'name': 'Gold ring',
              'price': '1500.00',
              'is_available': true,
              'status': 'active',
            },
          ],
          'last_page': 2,
          'total': 1,
        },
      };
      final result = ProductsListResult.fromResponseData(json);
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Gold ring');
      expect(result.hasMore, isTrue);
    });
  });

  group('PublicCatalogRepository.buildCategoryTree', () {
    test('builds tree from flat parent_id list', () {
      const parent = CategoryTreeModel(
        id: 1,
        name: 'Fashion',
        slug: 'fashion',
        parentId: null,
      );
      const child = CategoryTreeModel(
        id: 3,
        name: 'Shirts',
        slug: 'shirts',
        parentId: 1,
      );
      final tree = PublicCatalogRepository.buildCategoryTree([parent, child]);
      expect(tree.length, 1);
      expect(tree.first.id, 1);
      expect(tree.first.children.length, 1);
      expect(tree.first.children.first.name, 'Shirts');
    });
  });

  group('BranchModel', () {
    test('fromJson parses branch fields', () {
      final branch = BranchModel.fromJson({
        'id': 1,
        'name': 'Main Branch',
        'vendor_id': '7',
        'address': '123 Main St',
        'location_latitude': '40.712776',
        'location_longitude': '-74.005974',
        'distance': '0.003',
        'is_active': true,
      });
      expect(branch.id, 1);
      expect(branch.name, 'Main Branch');
      expect(branch.vendorId, 7);
      expect(branch.address, '123 Main St');
      expect(branch.distance, closeTo(0.003, 0.0001));
    });
  });
}
